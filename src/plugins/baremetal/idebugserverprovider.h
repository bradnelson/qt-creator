/****************************************************************************
**
** Copyright (C) 2019 Denis Shienkov <denis.shienkov@gmail.com>
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

#pragma once

#include <QObject>
#include <QSet>
#include <QVariantMap>
#include <QWidget>

#include <coreplugin/id.h>
#include <debugger/debuggerconstants.h>
#include <utils/fileutils.h>

QT_BEGIN_NAMESPACE
class QFormLayout;
class QLabel;
class QLineEdit;
class QSpinBox;
QT_END_NAMESPACE

namespace Debugger {
class DebuggerRunTool;
}

namespace ProjectExplorer {
class IDevice;
class RunControl;
class RunWorker;
}

namespace BareMetal {
namespace Internal {

class BareMetalDevice;
class IDebugServerProviderConfigWidget;

// IDebugServerProvider

class IDebugServerProvider
{
public:
    virtual ~IDebugServerProvider();

    QString displayName() const;
    void setDisplayName(const QString &name);

    QUrl channel() const;
    void setChannel(const QUrl &channel);
    void setChannel(const QString &host, int port);

    virtual QString channelString() const;

    QString id() const;
    QString typeDisplayName() const;
    Debugger::DebuggerEngineType engineType() const;

    virtual bool operator==(const IDebugServerProvider &other) const;

    virtual IDebugServerProviderConfigWidget *configurationWidget() = 0;

    virtual IDebugServerProvider *clone() const = 0;

    virtual QVariantMap toMap() const;

    virtual bool aboutToRun(Debugger::DebuggerRunTool *runTool,
                            QString &errorMessage) const = 0;
    virtual ProjectExplorer::RunWorker *targetRunner(
            ProjectExplorer::RunControl *runControl) const = 0;

    virtual bool isValid() const = 0;

    void registerDevice(BareMetalDevice *device);
    void unregisterDevice(BareMetalDevice *device);

protected:
    explicit IDebugServerProvider(const QString &id);
    explicit IDebugServerProvider(const IDebugServerProvider &provider);

    void setTypeDisplayName(const QString &typeDisplayName);
    void setEngineType(Debugger::DebuggerEngineType engineType);
    void setSettingsKeyBase(const QString &settingsBase);

    void providerUpdated();

    virtual bool fromMap(const QVariantMap &data);

    QString m_id;
    mutable QString m_displayName;
    QString m_typeDisplayName;
    QString m_settingsBase;
    QUrl m_channel;
    Debugger::DebuggerEngineType m_engineType = Debugger::NoEngineType;
    QSet<BareMetalDevice *> m_devices;

    friend class IDebugServerProviderConfigWidget;
};

// IDebugServerProviderFactory

class IDebugServerProviderFactory : public QObject
{
    Q_OBJECT

public:
    QString id() const;
    QString displayName() const;

    virtual IDebugServerProvider *create() = 0;

    virtual bool canRestore(const QVariantMap &data) const = 0;
    virtual IDebugServerProvider *restore(const QVariantMap &data) = 0;

    static QString idFromMap(const QVariantMap &data);
    static void idToMap(QVariantMap &data, const QString &id);

protected:
    void setId(const QString &id);
    void setDisplayName(const QString &name);

private:
    QString m_displayName;
    QString m_id;
};

// IDebugServerProviderConfigWidget

class IDebugServerProviderConfigWidget : public QWidget
{
    Q_OBJECT

public:
    explicit IDebugServerProviderConfigWidget(IDebugServerProvider *provider);

    virtual void apply();
    virtual void discard();

signals:
    void dirty();

protected:
    void setErrorMessage(const QString &);
    void clearErrorMessage();
    void addErrorLabel();
    void setFromProvider();

    IDebugServerProvider *m_provider = nullptr;
    QFormLayout *m_mainLayout = nullptr;
    QLineEdit *m_nameLineEdit = nullptr;
    QLabel *m_errorLabel = nullptr;
};

// HostWidget

class HostWidget final : public QWidget
{
    Q_OBJECT

public:
    explicit HostWidget(QWidget *parent = nullptr);

    void setChannel(const QUrl &host);
    QUrl channel() const;

signals:
    void dataChanged();

protected:
    QLineEdit *m_hostLineEdit = nullptr;
    QSpinBox *m_portSpinBox = nullptr;
};

} // namespace Internal
} // namespace BareMetal
