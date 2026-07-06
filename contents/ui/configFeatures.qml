import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: page

    property alias cfg_maxNotifications: maxSpin.value
    property alias cfg_popupWidth: popupWidthSpin.value
    property alias cfg_itemHeight: itemHeightSpin.value
    property alias cfg_bodyLines: bodyLinesSpin.value
    property alias cfg_fontSize: fontSizeSpin.value
    property alias cfg_showAppName: showAppNameCheck.checked
    property alias cfg_showTimestamp: showTimestampCheck.checked
    property alias cfg_showActions: showActionsCheck.checked
    property alias cfg_showDismissButton: showDismissButtonCheck.checked
    property alias cfg_backgroundEnabled: backgroundEnabledCheck.checked
    property alias cfg_borderEnabled: borderEnabledCheck.checked
    property alias cfg_animationsEnabled: animationsEnabledCheck.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        SpinBox {
            id: maxSpin
            Kirigami.FormData.label: i18n("Maximum notifications:")
            from: 1
            to: 20
        }

        SpinBox {
            id: popupWidthSpin
            Kirigami.FormData.label: i18n("Popup width:")
            from: 100
            to: 600
            stepSize: 10
        }

        SpinBox {
            id: itemHeightSpin
            Kirigami.FormData.label: i18n("Item height:")
            from: 20
            to: 160
            stepSize: 4
        }

        SpinBox {
            id: bodyLinesSpin
            Kirigami.FormData.label: i18n("Body line count:")
            from: 1
            to: 6
        }

        SpinBox {
            id: fontSizeSpin
            Kirigami.FormData.label: i18n("Font size:")
            from: 4
            to: 18
        }

        CheckBox {
            id: showAppNameCheck
            Kirigami.FormData.label: i18n("Show application name:")
        }

        CheckBox {
            id: showTimestampCheck
            Kirigami.FormData.label: i18n("Show timestamp:")
        }

        CheckBox {
            id: showActionsCheck
            Kirigami.FormData.label: i18n("Show action tags:")
        }

        CheckBox {
            id: showDismissButtonCheck
            Kirigami.FormData.label: i18n("Show dismiss button:")
        }

        CheckBox {
            id: backgroundEnabledCheck
            Kirigami.FormData.label: i18n("Show background:")
        }

        CheckBox {
            id: borderEnabledCheck
            Kirigami.FormData.label: i18n("Show border:")
        }

        CheckBox {
            id: animationsEnabledCheck
            Kirigami.FormData.label: i18n("Enable animations:")
        }
    }
}
