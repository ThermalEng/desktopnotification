import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
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
    property alias cfg_hideWhenEmpty: hideWhenEmptyCheck.checked
    property alias cfg_backgroundEnabled: backgroundEnabledCheck.checked
    property alias cfg_backgroundOpacity: backgroundOpacitySpin.value
    property alias cfg_backgroundColor: backgroundColorColorDialog.selectedColor
    property alias cfg_borderEnabled: borderEnabledCheck.checked
    property alias cfg_notificationOpacity: notificationOpacitySpin.value
    property alias cfg_notificationBgColor: notificationColorColorDialog.selectedColor
    property alias cfg_notificationBorderEnabled: notificationBorderEnabledCheck.checked
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
            id: hideWhenEmptyCheck
            Kirigami.FormData.label: i18n("Hide widget when notifications are empty:")
        }

        CheckBox {
            id: backgroundEnabledCheck
            Kirigami.FormData.label: i18n("Show background:")
        }

        SpinBox {
            id: backgroundOpacitySpin
            visible: backgroundEnabledCheck.checked
            Kirigami.FormData.label: i18n("Background opacity:")
            from: 1
            to: 100
            stepSize: 4
        }


        RowLayout {
            Layout.fillWidth: true
            visible: backgroundEnabledCheck.checked
            spacing: 10
            Kirigami.FormData.label: i18n("Background color:")

            Rectangle {
                id: colorPreview
                width: 34
                height: 28
                radius: 6
                color: cfg_backgroundColor
                border.color: "#718096"

                Layout.fillWidth: true
                border.width: 1
            }

            Button {
                text: i18n("Choose color")
                Layout.fillWidth: true
                onClicked: backgroundColorColorDialog.open()
            }
        }
        ColorDialog {
            id: backgroundColorColorDialog
            title: i18n("Choose Color")
            selectedColor: cfg_backgroundColor
        }

        CheckBox {
            id: borderEnabledCheck
            visible: backgroundEnabledCheck.checked
            Kirigami.FormData.label: i18n("Show border:")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Kirigami.FormData.label: i18n("Notification color:")

            Rectangle {
                id: notificationColorPreview
                width: 34
                height: 28
                radius: 6
                color: cfg_notificationBgColor
                border.color: "#718096"

                Layout.fillWidth: true
                border.width: 1
            }

            Button {
                text: i18n("Choose color")
                Layout.fillWidth: true
                onClicked: notificationColorColorDialog.open()
            }
        }
        ColorDialog {
            id: notificationColorColorDialog
            title: i18n("Choose Color")
            selectedColor: cfg_notificationBgColor
        }   

        SpinBox {
            id: notificationOpacitySpin
            Kirigami.FormData.label: i18n("Notification opacity:")
            from: 1
            to: 100
            stepSize: 4
        }

        CheckBox {
            id: notificationBorderEnabledCheck
            Kirigami.FormData.label: i18n("Show notifications border:")
        }

        CheckBox {
            id: animationsEnabledCheck
            Kirigami.FormData.label: i18n("Enable animations:")
        }
    }
}
