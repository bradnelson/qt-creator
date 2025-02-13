/****************************************************************************
**
** Copyright (C) 2019 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of Qt Creator.
**
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 as published by the Free Software
** Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
****************************************************************************/

import QtQuick 2.12
import QtQuick.Window 2.0
import QtQuick3D 1.0
import QtQuick.Controls 2.0
import QtGraphicalEffects 1.0

Window {
    id: viewWindow
    width: 1024
    height: 768
    visible: true
    title: "3D"
    flags: Qt.WindowStaysOnTopHint | Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint

    property alias scene: editView.importScene
    property alias showEditLight: btnEditViewLight.toggled
    property alias usePerspective: btnPerspective.toggled

    property Node selectedNode: null

    property var lightGizmos: []
    property var cameraGizmos: []
    property rect viewPortRect: Qt.rect(0, 0, 1000, 1000)

    signal objectClicked(var object)
    signal commitObjectProperty(var object, var propName)
    signal changeObjectProperty(var object, var propName)

    function selectObject(object) {
        selectedNode = object;
    }

    function handleObjectClicked(object) {
        var theObject = object;
        if (btnSelectGroup.selected) {
            while (theObject && theObject.parent !== scene)
                theObject = theObject.parent;
        }
        selectObject(theObject);
        objectClicked(theObject);
    }

    function addLightGizmo(obj)
    {
        var component = Qt.createComponent("LightGizmo.qml");
        if (component.status === Component.Ready) {
            var gizmo = component.createObject(overlayScene,
                                               {"view3D": overlayView, "targetNode": obj,
                                                "selectedNode": selectedNode});
            lightGizmos[lightGizmos.length] = gizmo;
            gizmo.clicked.connect(handleObjectClicked);
            gizmo.selectedNode = Qt.binding(function() {return selectedNode;});
        }
    }

    function addCameraGizmo(obj)
    {
        var component = Qt.createComponent("CameraGizmo.qml");
        if (component.status === Component.Ready) {
            var geometryName = _generalHelper.generateUniqueName("CameraGeometry");
            var gizmo = component.createObject(
                        overlayScene,
                        {"view3D": overlayView, "targetNode": obj, "geometryName": geometryName,
                         "viewPortRect": viewPortRect, "selectedNode": selectedNode});
            cameraGizmos[cameraGizmos.length] = gizmo;
            gizmo.clicked.connect(handleObjectClicked);
            gizmo.viewPortRect = Qt.binding(function() {return viewPortRect;});
            gizmo.selectedNode = Qt.binding(function() {return selectedNode;});
        }
    }

    // Work-around the fact that the projection matrix for the camera is not calculated until
    // the first frame is rendered, so any initial calls to mapFrom3DScene() will fail.
    Component.onCompleted: _generalHelper.requestOverlayUpdate();

    onWidthChanged: _generalHelper.requestOverlayUpdate();
    onHeightChanged: _generalHelper.requestOverlayUpdate();

    Node {
        id: overlayScene

        PerspectiveCamera {
            id: overlayPerspectiveCamera
            clipFar: editPerspectiveCamera.clipFar
            clipNear: editPerspectiveCamera.clipNear
            position: editPerspectiveCamera.position
            rotation: editPerspectiveCamera.rotation
        }

        OrthographicCamera {
            id: overlayOrthoCamera
            clipFar: editOrthoCamera.clipFar
            clipNear: editOrthoCamera.clipNear
            position: editOrthoCamera.position
            rotation: editOrthoCamera.rotation
            scale: editOrthoCamera.scale
        }

        MoveGizmo {
            id: moveGizmo
            scale: autoScale.getScale(Qt.vector3d(5, 5, 5))
            highlightOnHover: true
            targetNode: viewWindow.selectedNode
            position: viewWindow.selectedNode ? viewWindow.selectedNode.scenePosition
                                              : Qt.vector3d(0, 0, 0)
            globalOrientation: btnLocalGlobal.toggled
            visible: selectedNode && btnMove.selected
            view3D: overlayView

            onPositionCommit: viewWindow.commitObjectProperty(selectedNode, "position")
            onPositionMove: viewWindow.changeObjectProperty(selectedNode, "position")
        }

        ScaleGizmo {
            id: scaleGizmo
            scale: autoScale.getScale(Qt.vector3d(5, 5, 5))
            highlightOnHover: true
            targetNode: viewWindow.selectedNode
            position: viewWindow.selectedNode ? viewWindow.selectedNode.scenePosition
                                              : Qt.vector3d(0, 0, 0)
            globalOrientation: false
            visible: selectedNode && btnScale.selected
            view3D: overlayView

            onScaleCommit: viewWindow.commitObjectProperty(selectedNode, "scale")
            onScaleChange: viewWindow.changeObjectProperty(selectedNode, "scale")
        }

        RotateGizmo {
            id: rotateGizmo
            scale: autoScale.getScale(Qt.vector3d(7, 7, 7))
            highlightOnHover: true
            targetNode: viewWindow.selectedNode
            position: viewWindow.selectedNode ? viewWindow.selectedNode.scenePosition
                                              : Qt.vector3d(0, 0, 0)
            globalOrientation: btnLocalGlobal.toggled
            visible: selectedNode && btnRotate.selected
            view3D: overlayView

            onRotateCommit: viewWindow.commitObjectProperty(selectedNode, "rotation")
            onRotateChange: viewWindow.changeObjectProperty(selectedNode, "rotation")
        }

        AutoScaleHelper {
            id: autoScale
            view3D: overlayView
            position: moveGizmo.scenePosition
        }
    }

    Rectangle {
        anchors.fill: parent
        focus: true

        gradient: Gradient {
            GradientStop { position: 1.0; color: "#222222" }
            GradientStop { position: 0.0; color: "#999999" }
        }

        TapHandler { // check tapping/clicking an object in the scene
            onTapped: {
                var pickResult = editView.pick(eventPoint.scenePosition.x,
                                               eventPoint.scenePosition.y);
                handleObjectClicked(pickResult.objectHit);
            }
        }

        DropArea {
            anchors.fill: parent
        }

        View3D {
            id: editView
            anchors.fill: parent
            camera: usePerspective ? editPerspectiveCamera : editOrthoCamera

            Node {
                id: mainSceneHelpers

                HelperGrid {
                    id: helperGrid
                    lines: 50
                    step: 50
                }

                SelectionBox {
                    id: selectionBox
                    view3D: editView
                    targetNode: viewWindow.selectedNode
                }

                PointLight {
                    id: editLight
                    visible: showEditLight
                    position: usePerspective ? editPerspectiveCamera.position
                                             : editOrthoCamera.position
                    quadraticFade: 0
                    linearFade: 0
                }

                // Initial camera position and rotation should be such that they look at origin.
                // Otherwise EditCameraController._lookAtPoint needs to be initialized to correct
                // point.
                PerspectiveCamera {
                    id: editPerspectiveCamera
                    z: -600
                    y: 600
                    rotation.x: 45
                    clipFar: 100000
                    clipNear: 1
                }

                OrthographicCamera {
                    id: editOrthoCamera
                    z: -600
                    y: 600
                    rotation.x: 45
                    clipFar: 100000
                    clipNear: -10000
                }
            }
        }

        View3D {
            id: overlayView
            anchors.fill: parent
            camera: usePerspective ? overlayPerspectiveCamera : overlayOrthoCamera
            importScene: overlayScene
        }

        Overlay2D {
            id: gizmoLabel
            targetNode: moveGizmo.visible ? moveGizmo : scaleGizmo
            targetView: overlayView
            visible: targetNode.dragging

            Rectangle {
                color: "white"
                x: -width / 2
                y: -height - 8
                width: gizmoLabelText.width + 4
                height: gizmoLabelText.height + 4
                border.width: 1
                Text {
                    id: gizmoLabelText
                    text: {
                        var l = Qt.locale();
                        var targetProperty;
                        if (viewWindow.selectedNode) {
                            if (gizmoLabel.targetNode === moveGizmo)
                                targetProperty = viewWindow.selectedNode.position;
                            else
                                targetProperty = viewWindow.selectedNode.scale;
                            return qsTr("x:") + Number(targetProperty.x).toLocaleString(l, 'f', 1)
                                + qsTr(" y:") + Number(targetProperty.y).toLocaleString(l, 'f', 1)
                                + qsTr(" z:") + Number(targetProperty.z).toLocaleString(l, 'f', 1);
                        } else {
                            return "";
                        }
                    }
                    anchors.centerIn: parent
                }
            }
        }

        EditCameraController {
            id: cameraControl
            camera: editView.camera
            anchors.fill: parent
            view3d: editView
        }
    }

    Rectangle { // toolbar
        id: toolbar
        color: "#9F000000"
        width: 35
        height: col.height

        Column {
            id: col
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 5
            padding: 5

            property var groupSelect: [btnSelectGroup, btnSelectItem]
            property var groupTransform: [btnMove, btnRotate, btnScale]

            ToolBarButton {
                id: btnSelectItem
                selected: true
                tooltip: qsTr("Select Item")
                shortcut: "Q"
                currentShortcut: selected ? "" : shortcut
                tool: "item_selection"
                buttonsGroup: col.groupSelect
            }

            ToolBarButton {
                id: btnSelectGroup
                tooltip: qsTr("Select Group")
                shortcut: "Q"
                currentShortcut: btnSelectItem.currentShortcut === shortcut ? "" : shortcut
                tool: "group_selection"
                buttonsGroup: col.groupSelect
            }

            Rectangle { // separator
                width: 25
                height: 1
                color: "#f1f1f1"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ToolBarButton {
                id: btnMove
                selected: true
                tooltip: qsTr("Move current selection")
                shortcut: "W"
                currentShortcut: shortcut
                tool: "move"
                buttonsGroup: col.groupTransform
            }

            ToolBarButton {
                id: btnRotate
                tooltip: qsTr("Rotate current selection")
                shortcut: "E"
                currentShortcut: shortcut
                tool: "rotate"
                buttonsGroup: col.groupTransform
            }

            ToolBarButton {
                id: btnScale
                tooltip: qsTr("Scale current selection")
                shortcut: "R"
                currentShortcut: shortcut
                tool: "scale"
                buttonsGroup: col.groupTransform
            }

            Rectangle { // separator
                width: 25
                height: 1
                color: "#f1f1f1"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ToolBarButton {
                id: btnFit
                tooltip: qsTr("Fit camera to current selection")
                shortcut: "F"
                currentShortcut: shortcut
                tool: "fit"
                togglable: false

                onSelectedChanged: {
                    if (selected) {
                        var targetNode = viewWindow.selectedNode ? selectionBox.model : null;
                        cameraControl.fitObject(targetNode, editView.camera.rotation);
                    }
                }
            }
        }
    }

    AxisHelper {
        anchors.right: parent.right
        anchors.top: parent.top
        width: 100
        height: width
        editCameraCtrl: cameraControl
        selectedNode : viewWindow.selectedNode ? selectionBox.model : null
    }

    Rectangle { // top controls bar
        color: "#aa000000"
        width: 265
        height: btnPerspective.height + 10
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 100

        ToggleButton {
            id: btnPerspective
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.left: parent.left
            anchors.leftMargin: 5
            tooltip: qsTr("Toggle Perspective / Orthographic Projection")
            states: [{iconId: "ortho", text: qsTr("Orthographic")}, {iconId: "persp",  text: qsTr("Perspective")}]
        }

        ToggleButton {
            id: btnLocalGlobal
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.left: parent.left
            anchors.leftMargin: 100
            tooltip: qsTr("Toggle Global / Local Orientation")
            states: [{iconId: "local",  text: qsTr("Local")}, {iconId: "global", text: qsTr("Global")}]
        }

        ToggleButton {
            id: btnEditViewLight
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.left: parent.left
            anchors.leftMargin: 165
            toggleBackground: true
            tooltip: qsTr("Toggle Edit Light")
            states: [{iconId: "edit_light_off",  text: qsTr("Edit Light Off")}, {iconId: "edit_light_on", text: qsTr("Edit Light On")}]
        }
    }

    Text {
        id: helpText
        color: "white"
        text: qsTr("Camera controls: ALT + mouse press and drag. Left: Rotate, Middle: Pan, Right/Wheel: Zoom.")
        anchors.bottom: parent.bottom
    }
}
