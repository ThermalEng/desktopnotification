import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.core as PlasmaCore

// 单条通知的渲染。
// 所有外部依赖（通知角色 / config / 模型 / 父容器）都通过 property 注入，
// 避免文件级别的 Plasmoid 上下文耦合。
Item {
    id: itemRoot

    // === 注入的依赖（由 main.qml 在 delegate 里赋值） ===
    property var notificationsModel          // 用于 dismiss
    property var notificationIndex           // QPersistentModelIndex，避免行号变化后点错通知
    property var config                       // Plasmoid.configuration
    property var rootRef                      // 引用 main 的 root 以拿颜色等
    property bool showActions: true
    property bool showDismissButton: true

    property string summaryText: ""
    property string bodyText: ""
    property string appName: ""
    property string desktopEntry: ""
    property var appIcon: "applications-system"
    property var actionNames: []
    property var actionLabels: []
    property bool hasDefaultAction: false
    property string defaultActionLabel: ""
    property bool expired: false
    property var timestamp: null
    readonly property real scaleFactor: rootRef && rootRef.fontScale > 0 ? rootRef.fontScale : 1
    readonly property string cleanedBodyText: itemRoot.plainBodyText(itemRoot.bodyText)
    readonly property string displayBodyText: itemRoot.cleanedBodyText.length > 0
        ? itemRoot.cleanedBodyText
        : itemRoot.summaryText
    readonly property real cardPadding: 8 * itemRoot.scaleFactor

    function formatTime(t) {
        if (!t) return ""
        const d = new Date(t)
        const now = new Date()
        const sameDay = d.toDateString() === now.toDateString()
        const pad = (n) => n < 10 ? "0" + n : "" + n
        if (sameDay) return pad(d.getHours()) + ":" + pad(d.getMinutes())
        return pad(d.getMonth() + 1) + "-" + pad(d.getDate())
            + " " + pad(d.getHours()) + ":" + pad(d.getMinutes())
    }

    function dismiss() {
        if (notificationsModel && notificationIndex) {
            notificationsModel.close(notificationIndex)
        }
    }

    function invokeAction(name) {
        if (notificationsModel && notificationIndex && name && name.length > 0) {
            notificationsModel.invokeAction(notificationIndex, name, NotificationManager.Notifications.Close)
        }
    }

    function invokeDefaultAction() {
        if (notificationsModel && notificationIndex && hasDefaultAction) {
            notificationsModel.invokeDefaultAction(notificationIndex, NotificationManager.Notifications.Close)
        }
    }

    function plainBodyText(text) {
        let result = text || ""
        result = result.replace(/<br\s*\/?>/gi, "\n")
        result = result.replace(/<\/(p|div|li|tr|h[1-6])>/gi, "\n")
        result = result.replace(/<[^>]*>/g, "")
        result = result.replace(/&nbsp;/g, " ")
        result = result.replace(/&amp;/g, "&")
        result = result.replace(/&lt;/g, "<")
        result = result.replace(/&gt;/g, ">")
        result = result.replace(/&quot;/g, "\"")
        result = result.replace(/&#39;/g, "'")
        return result.replace(/\n{3,}/g, "\n\n").trim()
    }

    function animateIn() {
        itemRoot.opacity = 0
        itemRoot.scale = 0.96
        inAnim.restart()
    }

    SequentialAnimation {
        id: inAnim
        NumberAnimation {
            target: itemRoot; property: "opacity"; to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: itemRoot; property: "scale"; to: 1
            duration: 220
            easing.type: Easing.OutBack
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: config.cornerRadius
        color: config.backgroundEnabled
            ? Qt.rgba(1, 1, 1, 0.04)
            : Qt.rgba(0, 0, 0, 0)
        border.width: config.borderEnabled && config.backgroundEnabled ? 1 : 0
        border.color: rootRef.borderCol

        RowLayout {
            z: 2
            anchors.fill: parent
            anchors.margins: Math.round(itemRoot.cardPadding)
            spacing: Math.round(10 * itemRoot.scaleFactor)

            // ===== 应用图标 =====
            Kirigami.Icon {
                source: itemRoot.appIcon
                fallback: "applications-system"
                implicitWidth: Math.round(36 * itemRoot.scaleFactor)
                implicitHeight: Math.round(36 * itemRoot.scaleFactor)
                Layout.alignment: Qt.AlignVCenter
            }

            // ===== 标题/正文/关闭 =====
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * itemRoot.scaleFactor)

                // 标题行：应用名 + 标题 + 时间
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(6 * itemRoot.scaleFactor)

                    Label {
                        visible: config.showAppName && itemRoot.appName.length > 0
                        text: itemRoot.appName
                        color: rootRef.textSecondary
                        font.pointSize: 9 * itemRoot.scaleFactor
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.maximumWidth: Math.round(110 * itemRoot.scaleFactor)
                    }

                    Rectangle {
                        visible: config.showAppName && itemRoot.appName.length > 0
                        width: Math.round(3 * itemRoot.scaleFactor)
                        height: width
                        radius: width / 2
                        color: rootRef.textSecondary
                    }

                    Label {
                        text: itemRoot.summaryText.length > 0 ? itemRoot.summaryText : i18n("Notification")
                        color: rootRef.textPrimary
                        font.pointSize: 12 * itemRoot.scaleFactor
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Label {
                        visible: config.showTimestamp && itemRoot.timestamp
                        text: itemRoot.formatTime(itemRoot.timestamp)
                        color: rootRef.textSecondary
                        font.pointSize: 9 * itemRoot.scaleFactor
                    }
                }

                // 正文、action 标签和关闭按钮同一行，按钮贴近正文最后一行高度。
                RowLayout {
                    Layout.fillWidth: true
                    visible: itemRoot.displayBodyText.length > 0
                        || (itemRoot.showActions && (itemRoot.hasDefaultAction || itemRoot.actionNames.length > 0))
                        || itemRoot.showDismissButton
                    spacing: Math.round(6 * itemRoot.scaleFactor)

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignBottom
                        text: itemRoot.displayBodyText
                        textFormat: Text.PlainText
                        color: rootRef.textSecondary
                        font.pointSize: 11 * itemRoot.scaleFactor
                        wrapMode: Text.WordWrap
                        maximumLineCount: Math.max(1, config.bodyLines)
                        elide: Text.ElideRight
                        clip: true
                        visible: itemRoot.displayBodyText.length > 0
                    }

                    Repeater {
                        model: itemRoot.showActions
                            ? ((itemRoot.hasDefaultAction ? ["__default__"] : []).concat(itemRoot.actionNames))
                            : []

                        Rectangle {
                            z: 2
                            Layout.preferredHeight: Math.round(24 * itemRoot.scaleFactor)
                            Layout.alignment: Qt.AlignBottom
                            Layout.preferredWidth: actionLbl.implicitWidth + Math.round(18 * itemRoot.scaleFactor)
                            radius: height / 2
                            color: actionMouse.containsMouse
                                ? Qt.lighter(rootRef.accent, 1.15)
                                : rootRef.accent
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Label {
                                id: actionLbl
                                anchors.centerIn: parent
                                text: modelData === "__default__"
                                    ? (itemRoot.defaultActionLabel.length > 0 ? itemRoot.defaultActionLabel : i18n("Open"))
                                    : itemRoot.actionLabels[itemRoot.hasDefaultAction ? index - 1 : index] || modelData
                                color: "#ffffff"
                                font.pointSize: 10 * itemRoot.scaleFactor
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: function(mouse) {
                                    mouse.accepted = true
                                    if (modelData === "__default__") {
                                        itemRoot.invokeDefaultAction()
                                    } else {
                                        itemRoot.invokeAction(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // 关闭按钮
                    Rectangle {
                        z: 2
                        Layout.preferredWidth: Math.round(24 * itemRoot.scaleFactor)
                        Layout.preferredHeight: Math.round(24 * itemRoot.scaleFactor)
                        Layout.alignment: Qt.AlignBottom
                        radius: height / 2
                        visible: itemRoot.showDismissButton
                        color: dismissMouse.containsMouse
                            ? Qt.rgba(1, 1, 1, 0.18)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Label {
                            anchors.centerIn: parent
                            text: "\u00d7"
                            color: rootRef.textSecondary
                            font.pointSize: 11 * itemRoot.scaleFactor
                        }
                        MouseArea {
                            id: dismissMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: function(mouse) {
                                mouse.accepted = true
                                itemRoot.dismiss()
                            }
                        }
                    }
                }
            }
        }

    }
}
