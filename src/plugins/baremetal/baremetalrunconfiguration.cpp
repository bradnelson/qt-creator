/****************************************************************************
**
** Copyright (C) 2016 Tim Sander <tim@krieglstein.org>
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

#include "baremetalconstants.h"
#include "baremetalrunconfiguration.h"

#include <projectexplorer/buildsystem.h>
#include <projectexplorer/buildtargetinfo.h>
#include <projectexplorer/project.h>
#include <projectexplorer/runconfigurationaspects.h>
#include <projectexplorer/target.h>

using namespace ProjectExplorer;
using namespace Utils;

namespace BareMetal {
namespace Internal {

// BareMetalRunConfiguration

BareMetalRunConfiguration::BareMetalRunConfiguration(Target *target, Core::Id id)
    : RunConfiguration(target, id)
{
    const auto exeAspect = addAspect<ExecutableAspect>();
    exeAspect->setDisplayStyle(BaseStringAspect::LabelDisplay);
    exeAspect->setPlaceHolderText(tr("Unknown"));

    addAspect<ArgumentsAspect>();
    addAspect<WorkingDirectoryAspect>();

    setUpdater([this, exeAspect] {
        const BuildTargetInfo bti = buildTargetInfo();
        exeAspect->setExecutable(bti.targetFilePath);
        emit enabledChanged();
    });

    connect(target, &Target::buildSystemUpdated, this, &RunConfiguration::update);
}

const char *BareMetalRunConfiguration::IdPrefix = "BareMetalCustom";

// BareMetalRunConfigurationFactory

BareMetalRunConfigurationFactory::BareMetalRunConfigurationFactory()
{
    registerRunConfiguration<BareMetalRunConfiguration>(BareMetalRunConfiguration::IdPrefix);
    setDecorateDisplayNames(true);
    addSupportedTargetDeviceType(BareMetal::Constants::BareMetalOsType);
}

} // namespace Internal
} // namespace BareMetal

