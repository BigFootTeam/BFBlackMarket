if not LOCALE_zhCN then return end
local L = select( 2, ...).L

L["BFBlackMarket"] = "大脚黑市"
L["BFBM"] = "大脚黑市"
L["New version (%s) available! Please consider updating."] = "发现新版本(%s)，建议您更新。"
L["Click this button to open BFBlackMarket"] = "点击此按钮打开大脚黑市"

L["CURRENT"] = "当前商品"
L["HISTORY"] = "历史记录"
L["Config"] = "设置"

-- current
L["Current Server"] = "当前服务器"
L["Last Update"] = "最后更新"
L["Only update time when data changes"] = "仅在数据变化时更新时间"
L["No data"] = "没有数据"
L["Servers"] = "服务器"
L["Click here to switch servers"] = "点击这里切换服务器"

-- history
L["Avg"] = "均价"
L["Add Item to Watchlist"] = "添加物品到关注列表"
L["Item ID"] = "物品ID"
L["No items found"] = "没有找到物品"
L["items"] = "物品"
L["Alt + Left Click to delete item"] = "Alt+左键点击以删除物品"

-- config
L["Hold Ctrl to show item tooltips"] = "按住Ctrl键显示物品鼠标提示"
L["No data receiving in instances"] = "在副本时不接收数据"
L["Price change alerts"] = "价格变化提醒"
L["Show notification popups when watched items change price"] = "当关注的物品价格变化时显示通知弹窗"
L["Auto wipe outdated server data"] = "自动清除过期的服务器数据"
L["Server history data will be preserved"] = "服务器的历史数据将被保留"
L["Never"] = "从不"
L["Current Server Only"] = "仅当前服务器"
L["All Servers"] = "所有服务器"
L["Chat messages on BM changes"] = "黑市数据变化时显示聊天消息"
L["Chat messages interval"] = "聊天消息间隔"
L["Instant"] = "即时"

-- detail
L["Available on %s servers"] = "正在 %s 个服务器上拍卖"

-- popup
L["%s\nis on the Black Market!\nCurrent bid: %s\nServer: %s"] = "%s\n在黑市上架了！\n当前竞标价：%s\n服务器：%s"
L["%s\nYou've been outbid!\nCurrent bid: %s\nServer: %s"] = "%s\n你的出价已被超过！\n当前竞标价：%s\n服务器：%s"
L["%s\nThe bid price has changed!\nCurrent bid: %s\nServer: %s"] = "%s\n竞标价发生了变化！\n当前竞标价：%s\n服务器：%s"

-- chat
L["%s data updated, click %s to view details!"] = "%s的数据已更新，可以点击%s查看哦！"
L["here"] = "这里"