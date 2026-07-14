import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ===== 颜色/尺寸/动画快捷属性 =====
    readonly property bool animationsEnabled: Plasmoid.configuration.animationsEnabled
    readonly property real animMultiplier: 100 / Math.max(40, Plasmoid.configuration.animationSpeed)
    function dur(ms) {
        return animationsEnabled ? Math.round(ms * animMultiplier) : 0
    }
    function withAlpha(c, percent) {
        return Qt.rgba(c.r, c.g, c.b, Math.max(0, Math.min(100, percent)) / 100)
    }
    function clearVisibleNotifications() {
        for (let row = notificationsModel.count - 1; row >= 0; --row) {
            notificationsModel.close(notificationsModel.index(row, 0))
        }
        notificationsModel.clear(NotificationManager.Notifications.ClearExpired)
    }

    readonly property bool backgroundVisible: Plasmoid.configuration.backgroundEnabled
    readonly property color configuredBackgroundColor: Plasmoid.configuration.backgroundColor
    readonly property color configuredNotificationColor: Plasmoid.configuration.notificationBgColor
    readonly property color configuredNotificationColorWithOpacity: withAlpha(configuredNotificationColor, Plasmoid.configuration.notificationOpacity)  
    readonly property color panelBg: root.backgroundVisible
        ? withAlpha(root.configuredBackgroundColor, Plasmoid.configuration.backgroundOpacity)
        : "transparent"
    readonly property color borderCol: Plasmoid.configuration.borderEnabled
        ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0)
    readonly property color textPrimary: Plasmoid.configuration.textColor
    readonly property color textSecondary: Plasmoid.configuration.subTextColor
    readonly property color accent: Plasmoid.configuration.accentColor
    readonly property real baseFontSize: Plasmoid.configuration.fontSize > 0
        ? Plasmoid.configuration.fontSize
        : 11
    readonly property real fontScale: root.baseFontSize / 11
    readonly property int bodyLineCount: Math.max(1, Plasmoid.configuration.bodyLines)
    readonly property int bodyAwareItemHeight: Math.max(
        Plasmoid.configuration.itemHeight,
        Math.round((root.bodyLineCount + 7.5) * root.baseFontSize * 1.2)
    )
    readonly property int scaledItemHeight: Math.round(root.bodyAwareItemHeight * root.fontScale)
    readonly property int scaledPopupWidth: Math.round(root.popupWidth * root.fontScale)

    // 面板上常驻胶囊的图标（始终显示）
    Plasmoid.icon: "notifications"
    Plasmoid.title: "Desktop Notification"
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? fullRepresentation
        : compactRepresentation

    // ============== 状态 ==============
    property bool popupOpen: false
    property int unreadCount: 0
    readonly property var notificationSource: notificationsModel
    readonly property int popupWidth: Plasmoid.configuration.popupWidth
    readonly property bool planarMode: Plasmoid.formFactor === PlasmaCore.Types.Planar
    readonly property int notificationCount: notificationsModel.count
    readonly property int maxNotifications: Math.max(1, Plasmoid.configuration.maxNotifications)
    readonly property string compactLabel: i18np("%1 notification", "%1 notifications", root.notificationCount)
    readonly property int compactWidth: root.notificationCount > 0 ? Math.ceil(compactTextMetrics.width) + Math.round(64 * root.fontScale) : 0
    readonly property int compactHeight: root.notificationCount > 0 ? Math.round(30 * root.fontScale) : 0

    Layout.minimumWidth: root.planarMode ? Math.round(root.popupWidth * 0.6 * root.fontScale) : root.compactWidth
    Layout.minimumHeight: root.planarMode ? Math.round(root.scaledItemHeight * 1.2) : root.compactHeight
    Layout.preferredWidth: root.planarMode ? root.scaledPopupWidth : root.compactWidth
    Layout.preferredHeight: root.planarMode ? Math.max(
        Math.round(root.scaledItemHeight * root.maxNotifications + root.compactHeight),
        Math.round(120 * root.fontScale)
    ) : root.compactHeight
    Layout.maximumWidth: root.planarMode ? 100000 : root.compactWidth
    Layout.maximumHeight: root.planarMode ? 100000 : root.compactHeight

    implicitWidth: root.planarMode ? root.scaledPopupWidth : root.compactWidth
    implicitHeight: root.planarMode ? Math.max(
        Math.round(root.scaledItemHeight * root.maxNotifications + root.compactHeight),
        Math.round(120 * root.fontScale)
    ) : root.compactHeight

    TextMetrics {
        id: compactTextMetrics
        text: root.compactLabel
        font.pointSize: 11 * root.fontScale
        font.weight: Font.Medium
    }

    function persistentNotificationIndex(row) {
        return notificationsModel.makePersistentModelIndex(notificationsModel.index(row, 0))
    }

    function notificationIcon(image, iconName, applicationIconName) {
        if (image) {
            return image
        }
        if (iconName && iconName.length > 0) {
            return iconName
        }
        if (applicationIconName && applicationIconName.length > 0) {
            return applicationIconName
        }
        return "applications-system"
    }

    // ===== 通知数据源（直接挂到 KDE 通知管理器） =====
    NotificationManager.Notifications {
        id: notificationsModel
        // 绑定到配置项，运行时改 maxNotifications 也会立即生效
        limit: Math.max(1, Plasmoid.configuration.maxNotifications)
        showExpired: true
        showDismissed: false
        showNotifications: true
        showJobs: false
        sortMode: NotificationManager.Notifications.SortByDate
        sortOrder: Qt.DescendingOrder   // 最新在最前
        groupMode: NotificationManager.Notifications.GroupDisabled

        onUnreadNotificationsCountChanged: root.unreadCount = unreadNotificationsCount
        onCountChanged: {
            if (count === 0) {
                root.closePopup()
            }
        }
    }

    // 监听 "新增通知" 信号，做平滑插入动画
    Connections {
        target: NotificationManager.Server
        function onNotificationAdded(notification) {
            flashTimer.restart()
        }
    }

    Timer {
        id: flashTimer
        interval: 800
        repeat: false
    }

    // ============== 布局 ==============
    // 折叠态：任务栏上一个胶囊，点击展开
    compactRepresentation: Item {
        id: compact
        implicitWidth: root.compactWidth
        implicitHeight: root.compactHeight

        Rectangle {
            id: capsule
            visible: Plasmoid.configuration.hideWhenEmpty ? notificationsModel.count > 0 : true
            anchors.centerIn: parent
            width: root.compactWidth
            height: root.compactHeight
            radius: height / 2
            color: root.panelBg
            border.width: Plasmoid.configuration.borderEnabled && root.backgroundVisible ? 1 : 0
            border.color: root.borderCol

            RowLayout {
                id: compactRow
                anchors.centerIn: parent
                spacing: Math.round(8 * root.fontScale)

                Kirigami.Icon {
                    source: "notifications"
                    implicitWidth: Math.round(16 * root.fontScale)
                    implicitHeight: Math.round(16 * root.fontScale)
                    color: root.unreadCount > 0 ? root.accent : root.textPrimary
                }

                Label {
                    text: root.compactLabel
                    color: root.textPrimary
                    font.pointSize: 11 * root.fontScale
                    font.weight: Font.Medium
                }

                Rectangle {
                    visible: root.unreadCount > 0 && flashTimer.running
                    width: Math.round(8 * root.fontScale)
                    height: width
                    radius: height / 2
                    color: root.accent

                    SequentialAnimation on opacity {
                        running: parent.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: root.dur(400); easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: root.dur(400); easing.type: Easing.InOutSine }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: notificationsModel.count > 0
                onClicked: root.togglePopup()
            }
        }
    }

    // 桌面态：直接显示完整通知列表。面板态仍使用 compactRepresentation + popup。
    fullRepresentation: Item {
        id: desktopFull

        Rectangle {
            id: desktopBg
            visible: Plasmoid.configuration.hideWhenEmpty ? notificationsModel.count > 0 : true
            anchors.fill: parent
            radius: Plasmoid.configuration.cornerRadius
            color: root.panelBg
            border.width: Plasmoid.configuration.borderEnabled && root.backgroundVisible ? 1 : 0
            border.color: root.borderCol

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.fontScale)
                spacing: Math.round(6 * root.fontScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * root.fontScale)

                    Kirigami.Icon {
                        source: "notifications"
                        implicitWidth: Math.round(18 * root.fontScale)
                        implicitHeight: Math.round(18 * root.fontScale)
                        color: root.accent
                    }

                    Label {
                        text: i18n("Notifications")
                        color: root.textPrimary
                        font.pointSize: 13 * root.fontScale
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Label {
                        text: i18np("%1 notification", "%1 notifications", notificationsModel.count)
                        color: root.textSecondary
                        font.pointSize: 10 * root.fontScale
                    }

                    ToolButton {
                        visible: notificationsModel.count > 0
                        text: i18n("Clear")
                        font.pointSize: 10 * root.fontScale
                        onClicked: root.clearVisibleNotifications()
                    }
                }

                ListView {
                    id: desktopList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    interactive: true
                    spacing: Math.round(6 * root.fontScale)
                    model: notificationsModel
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: NotificationItem {
                        width: desktopList.width
                        height: root.scaledItemHeight
                        summaryText: model.summary || ""
                        bodyText: model.body || ""
                        appName: model.applicationName || ""
                        desktopEntry: model.desktopEntry || ""
                        appIcon: root.notificationIcon(model.image, model.iconName, model.applicationIconName)
                        actionNames: model.actionNames || []
                        actionLabels: model.actionLabels || []
                        defaultActionLabel: model.defaultActionLabel || ""
                        hasDefaultAction: model.hasDefaultAction || false
                        timestamp: model.created
                        expired: model.expired || false
                        notificationIndex: root.persistentNotificationIndex(index)
                        notificationsModel: root.notificationSource
                        config: Plasmoid.configuration
                        notificationColor: configuredNotificationColorWithOpacity
                        rootRef: root
                        showActions: Plasmoid.configuration.showActions
                        showDismissButton: Plasmoid.configuration.showDismissButton
                    }
                }
            }
        }
    }

    // ============== 弹窗 ==============
    PlasmaCore.Dialog {
        id: popup
        visualParent: root
        location: Plasmoid.location
        visible: false
        color: Qt.rgba(0, 0, 0, 0)
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.NoBackground
        flags: Qt.Tool | Qt.WindowStaysOnTopHint

        // 放在胶囊下方/上方
        x: Math.round((root.width - root.scaledPopupWidth) / 2)
        y: {
            const h = root.height + Plasmoid.configuration.popupGap
            if (Plasmoid.location === PlasmaCore.Types.TopEdge) return -height - h
            return h
        }

        mainItem: Item {
            id: popupRoot
            width: root.scaledPopupWidth
            height: popupBg.height + Math.round(12 * root.fontScale)
            opacity: root.popupOpen ? 1 : 0
            scale: root.popupOpen ? 1 : 0.94

            Behavior on opacity { NumberAnimation { duration: root.dur(140); easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: root.dur(180); easing.type: Easing.OutBack } }

            // 离开整个 popup（包含背景）就关闭
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onExited: {
                    if (root.popupOpen) root.closePopup()
                }
            }

            Rectangle {
                id: popupBg
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.round(6 * root.fontScale)
                width: popupRoot.width
                height: listCol.implicitHeight + Math.round(16 * root.fontScale)
                radius: Plasmoid.configuration.cornerRadius
                color: root.panelBg
                border.width: Plasmoid.configuration.borderEnabled && root.backgroundVisible ? 1 : 0
                border.color: root.borderCol

                ColumnLayout {
                    id: listCol
                    anchors.fill: parent
                    anchors.margins: Math.round(8 * root.fontScale)
                    spacing: Math.round(6 * root.fontScale)

                    // 标题行
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(8 * root.fontScale)

                        Kirigami.Icon {
                            source: "notifications"
                            implicitWidth: Math.round(18 * root.fontScale)
                            implicitHeight: Math.round(18 * root.fontScale)
                            color: root.accent
                        }

                        Label {
                            text: i18n("Notifications")
                            color: root.textPrimary
                            font.pointSize: 13 * root.fontScale
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Label {
                            visible: root.unreadCount > 0
                            text: i18np("%1 unread", "%1 unread", root.unreadCount)
                            color: root.textSecondary
                            font.pointSize: 10 * root.fontScale
                        }

                        ToolButton {
                            id: closeAllBtn
                            visible: notificationsModel.count > 0
                            text: i18n("Clear")
                            font.pointSize: 10 * root.fontScale
                            onClicked: root.clearVisibleNotifications()
                        }
                    }

                    // 通知列表（最新在最上面）
                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(
                            notificationsModel.count * root.scaledItemHeight,
                            6 * root.scaledItemHeight
                        )
                        clip: true
                        interactive: true
                        spacing: Math.round(6 * root.fontScale)
                        model: notificationsModel
                        boundsBehavior: Flickable.StopAtBounds

                        // 监听模型行数变化，做插入动画
                        Connections {
                            target: notificationsModel
                            function onRowsInserted(parent, first, last) {
                                // 把新增项动画到可见位置
                                const item = list.itemAtIndex(first)
                                if (item) item.animateIn()
                            }
                        }

                        delegate: NotificationItem {
                            width: list.width
                            height: root.scaledItemHeight
                            summaryText: model.summary || ""
                            bodyText: model.body || ""
                            appName: model.applicationName || ""
                            desktopEntry: model.desktopEntry || ""
                            appIcon: root.notificationIcon(model.image, model.iconName, model.applicationIconName)
                            actionNames: model.actionNames || []
                            actionLabels: model.actionLabels || []
                            defaultActionLabel: model.defaultActionLabel || ""
                            hasDefaultAction: model.hasDefaultAction || false
                            timestamp: model.created
                            expired: model.expired || false
                            notificationIndex: root.persistentNotificationIndex(index)
                            notificationsModel: root.notificationSource
                            config: Plasmoid.configuration
                            notificationColor: configuredNotificationColorWithOpacity
                            rootRef: root
                            showActions: Plasmoid.configuration.showActions
                            showDismissButton: Plasmoid.configuration.showDismissButton
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (!visible) {
                root.popupOpen = false
            }
        }
    }
    function openPopup() {
        if (notificationsModel.count === 0) return
        popup.visible = true
        popupOpen = true
    }
    function closePopup() {
        popupOpen = false
        // 略微延迟关闭，给关闭动画播放的时间
        closeTimer.restart()
    }
    function togglePopup() {
        if (popupOpen) closePopup()
        else openPopup()
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!root.popupOpen) popup.visible = false
        }
    }
}
