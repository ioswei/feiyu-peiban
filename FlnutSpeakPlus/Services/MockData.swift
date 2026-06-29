import Foundation

enum MockData {
    static let aliasPool = [
        "夜航者", "拾光人", "深海鱼", "星尘客", "晚风信使",
        "孤岛旅人", "月光下", "云中鹤", "沉默树", "远方来信",
        "听风者", "半醒人", "潮汐声", "微光里", "路过人间"
    ]

    static let chatReplies = [
        "我也常常感到孤独，但今晚有你说话真好。",
        "谢谢你愿意听我说这些。",
        "也许我们都不需要被理解，只需要被陪伴。",
        "你的文字很温柔，像海面上的月光。",
        "下次还想再聊聊吗？",
        "我懂那种感觉，像夜里独自对着窗发呆。",
        "能遇见你，是这个夜晚最好的意外。",
        "不用急着说什么，就这样陪着也很好。",
        "今天也辛苦了，记得早点休息。",
        "你的话让我想起了某个同样安静的夜晚。"
    ]

    static let quickReplies = [
        "我懂你的感受。",
        "谢谢你愿意说这些。",
        "今晚也在想你说的那些话。",
        "你并不孤单。",
        "想继续聊聊吗？"
    ]

    static let dailyWhispers = [
        "有些心事不必说出口，放进瓶里就好。",
        "深夜的海洋从不会拒绝任何一只漂流瓶。",
        "孤独不是终点，是遇见同频灵魂的前奏。",
        "你值得被温柔地听见。",
        "也许回应正在漂来的路上。",
        "把今天放下，留给明天的自己。",
        "每一次投递，都是一次勇敢的自我拥抱。"
    ]

    static let avatarEmojis = ["🌊", "🫧", "🌙", "✨", "🐚", "⭐", "💫", "🦋", "🌸", "🔮"]

    static let achievements: [Achievement] = [
        Achievement(id: "first_throw", title: "初次投递", detail: "扔出第一只漂流瓶", icon: "paperplane.fill", requiredCount: 1),
        Achievement(id: "first_catch", title: "拾瓶人", detail: "捡到第一只漂流瓶", icon: "hand.wave.fill", requiredCount: 1),
        Achievement(id: "first_encounter", title: "灵魂邂逅", detail: "开启第一段对话", icon: "heart.fill", requiredCount: 1),
        Achievement(id: "mood_voice", title: "心情发声", detail: "发布第一条心情", icon: "heart.text.square.fill", requiredCount: 1),
        Achievement(id: "diary_keeper", title: "夜记旅人", detail: "写下第一篇私密日记", icon: "book.closed.fill", requiredCount: 1),
        Achievement(id: "throw_5", title: "信使", detail: "累计扔出 5 只漂流瓶", icon: "envelope.fill", requiredCount: 5),
        Achievement(id: "catch_5", title: "拾光者", detail: "累计捡到 5 只漂流瓶", icon: "sparkles", requiredCount: 5),
        Achievement(id: "companion_30", title: "夜航陪伴", detail: "陪伴模式累计 30 分钟", icon: "moon.stars.fill", requiredCount: 30)
    ]

    static func dailyWhisper(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return dailyWhispers[day % dailyWhispers.count]
    }

    static func randomAlias(excluding name: String) -> String {
        aliasPool.filter { $0 != name }.randomElement() ?? "偶遇者"
    }

    // MARK: - 本地种子数据（新用户默认体验）

    static func makeInitialSnapshot(userAlias: String) -> AppSnapshot {
        let now = Date()

        let bottles = communityBottles(now: now, count: 10)
        let posts = communityPosts(now: now, count: 6)
        let comments = sampleComments(for: posts, now: now)

        let conversation = Conversation(
            partnerAlias: "拾光人",
            partnerMood: .peaceful,
            lastMessage: "今晚的风很温柔，你也是。",
            lastMessageAt: now.addingTimeInterval(-900),
            unreadCount: 1,
            messages: [
                ChatMessage(content: "你好，我捡到了你的瓶子：「今天下班路过海边…」", isFromMe: false, sentAt: now.addingTimeInterval(-7200)),
                ChatMessage(content: "没想到真的有人回应，谢谢你。", isFromMe: true, sentAt: now.addingTimeInterval(-7000)),
                ChatMessage(content: "我也常常去海边，那里让人安静。", isFromMe: false, sentAt: now.addingTimeInterval(-6800)),
                ChatMessage(content: "今晚的风很温柔，你也是。", isFromMe: false, sentAt: now.addingTimeInterval(-900))
            ],
            originBottleContent: "今天下班路过海边，风很大，但心里突然安静了。"
        )

        let notifications: [AppNotification] = [
            AppNotification(
                title: "欢迎来到飞语陪伴",
                body: "把心事装进漂流瓶，也许今晚就能遇见另一个灵魂。",
                createdAt: now.addingTimeInterval(-120),
                kind: .reminder
            ),
            AppNotification(
                title: "拾光人",
                body: "今晚的风很温柔，你也是。",
                createdAt: now.addingTimeInterval(-900),
                kind: .newMessage
            )
        ]

        return AppSnapshot(
            userAlias: userAlias,
            userSignature: "把说不出口的话，交给海洋。",
            oceanBottles: bottles,
            thrownBottles: [],
            moodPosts: posts,
            conversations: [conversation],
            notifications: notifications,
            caughtBottleIDs: [],
            moodComments: comments,
            profileAvatarEmoji: "🌊"
        )
    }

    // MARK: - 本地种子数据（完整体验，与线上一致的自然内容）

    static func makeRichLocalSnapshot(userAlias: String) -> AppSnapshot {
        let now = Date()

        let myThrown: [DriftBottle] = [
            DriftBottle(
                content: "加班到十一点，走出公司大楼的时候，发现整座城市都安静了。想问问，还有谁也没睡吗？",
                mood: .lonely,
                authorAlias: userAlias,
                createdAt: daysAgo(2, hour: 23, from: now),
                isAnonymous: false
            ),
            DriftBottle(
                content: "今天鼓起勇气对一个陌生人说了谢谢，对方回了一个微笑。很小的事，但开心了一整天。",
                mood: .grateful,
                authorAlias: userAlias,
                createdAt: daysAgo(5, hour: 19, from: now),
                isAnonymous: true
            ),
            DriftBottle(
                content: "有时候觉得，能在这里写下一句话，就已经是一种被治愈。",
                mood: .peaceful,
                authorAlias: userAlias,
                createdAt: daysAgo(9, hour: 22, from: now),
                isAnonymous: true
            )
        ]

        var ocean = communityBottles(now: now, count: 14)
        ocean.insert(contentsOf: myThrown, at: 0)

        let myPosts: [MoodPost] = [
            MoodPost(
                content: "第一次在这里发心情，有点紧张。但如果有人看见，希望你知道——你并不孤单。",
                mood: .hopeful,
                authorAlias: userAlias,
                createdAt: daysAgo(3, hour: 21, from: now),
                likeCount: 34
            ),
            MoodPost(
                content: "连续三天写日记了。原来把情绪写下来，真的会轻松一点。",
                mood: .peaceful,
                authorAlias: userAlias,
                createdAt: daysAgo(1, hour: 8, from: now),
                likeCount: 18
            )
        ]

        var posts = communityPosts(now: now, count: 10)
        posts.insert(contentsOf: myPosts, at: 0)

        let comments = seedComments(for: posts, userAlias: userAlias, now: now)

        let caughtBottle1 = ocean.first { $0.authorAlias == "拾光人" } ?? ocean[1]
        let caughtBottle2 = ocean.first { $0.authorAlias == "深海鱼" } ?? ocean[2]
        let caughtBottle3 = ocean.first { $0.authorAlias == "星尘客" } ?? ocean[3]

        let caughtHistory: [CaughtBottleRecord] = [
            CaughtBottleRecord(bottle: caughtBottle1, caughtAt: daysAgo(4, hour: 20, from: now)),
            CaughtBottleRecord(bottle: caughtBottle2, caughtAt: daysAgo(7, hour: 23, from: now)),
            CaughtBottleRecord(bottle: caughtBottle3, caughtAt: daysAgo(12, hour: 1, from: now))
        ]

        let conversations: [Conversation] = [
            Conversation(
                partnerAlias: "拾光人",
                partnerMood: .peaceful,
                lastMessage: "今晚的风很温柔，你也是。",
                lastMessageAt: now.addingTimeInterval(-900),
                unreadCount: 1,
                messages: [
                    ChatMessage(content: "你好，我捡到了你的瓶子：「今天下班路过海边…」", isFromMe: false, sentAt: daysAgo(4, hour: 20, from: now)),
                    ChatMessage(content: "没想到真的有人回应，谢谢你。", isFromMe: true, sentAt: daysAgo(4, hour: 20, from: now).addingTimeInterval(600)),
                    ChatMessage(content: "我也常常去海边，那里让人安静。", isFromMe: false, sentAt: daysAgo(4, hour: 19, from: now)),
                    ChatMessage(content: "你平时也会一个人去走走吗？", isFromMe: true, sentAt: daysAgo(3, hour: 22, from: now)),
                    ChatMessage(content: "会啊，尤其是心情乱的时候。走着走着，好像就没那么糟了。", isFromMe: false, sentAt: daysAgo(3, hour: 21, from: now)),
                    ChatMessage(content: "今晚的风很温柔，你也是。", isFromMe: false, sentAt: now.addingTimeInterval(-900))
                ],
                originBottleContent: "今天下班路过海边，风很大，但心里突然安静了。"
            ),
            Conversation(
                partnerAlias: "深海鱼",
                partnerMood: .melancholy,
                lastMessage: "嗯，我懂。",
                lastMessageAt: daysAgo(2, hour: 23, from: now),
                unreadCount: 0,
                messages: [
                    ChatMessage(content: "你好，我捡到了你的瓶子：「不知道自己在等什么…」", isFromMe: false, sentAt: daysAgo(7, hour: 23, from: now)),
                    ChatMessage(content: "有时候我也这样，好像只是在等一个回应。", isFromMe: true, sentAt: daysAgo(7, hour: 22, from: now)),
                    ChatMessage(content: "嗯，我懂。", isFromMe: false, sentAt: daysAgo(2, hour: 23, from: now))
                ],
                originBottleContent: "不知道自己在等什么，也许只是在等一个回应。"
            ),
            Conversation(
                partnerAlias: "微光里",
                partnerMood: .peaceful,
                lastMessage: "晚安，明天会更好的。",
                lastMessageAt: daysAgo(1, hour: 23, from: now),
                unreadCount: 0,
                messages: [
                    ChatMessage(content: "你在广场发的那条动态，我看了。", isFromMe: false, sentAt: daysAgo(2, hour: 10, from: now)),
                    ChatMessage(content: "谢谢你来留言，没想到会有人认真看。", isFromMe: true, sentAt: daysAgo(2, hour: 9, from: now)),
                    ChatMessage(content: "给自己泡杯热茶，慢慢把今天放下。", isFromMe: false, sentAt: daysAgo(1, hour: 23, from: now)),
                    ChatMessage(content: "晚安，明天会更好的。", isFromMe: false, sentAt: daysAgo(1, hour: 23, from: now))
                ],
                originBottleContent: ""
            )
        ]

        let diaryEntries: [DiaryEntry] = (0..<6).map { offset in
            DiaryEntry(
                content: seedDiaryTexts[offset % seedDiaryTexts.count],
                mood: [.lonely, .peaceful, .melancholy, .hopeful, .grateful, .restless][offset % 6],
                createdAt: daysAgo(offset, hour: 22, from: now)
            )
        }

        let notifications: [AppNotification] = [
            AppNotification(title: "欢迎来到飞语陪伴", body: "把心事装进漂流瓶，也许今晚就能遇见另一个灵魂。", createdAt: daysAgo(14, hour: 10, from: now), isRead: true, kind: .reminder),
            AppNotification(title: "成就解锁 · 拾瓶人", body: "捡到第一只漂流瓶", createdAt: daysAgo(12, hour: 1, from: now), isRead: true, kind: .encounter),
            AppNotification(title: "成就解锁 · 灵魂邂逅", body: "开启第一段对话", createdAt: daysAgo(4, hour: 20, from: now), isRead: true, kind: .encounter),
            AppNotification(title: "拾光人", body: "今晚的风很温柔，你也是。", createdAt: now.addingTimeInterval(-900), kind: .newMessage),
            AppNotification(title: "你捡到了一个漂流瓶", body: "一位期待的灵魂向你漂来…", createdAt: daysAgo(1, hour: 21, from: now), isRead: true, kind: .bottleCaught),
            AppNotification(title: "微光里", body: "晚安，明天会更好的。", createdAt: daysAgo(1, hour: 23, from: now), isRead: true, kind: .newMessage),
            AppNotification(title: "漂流瓶已出发", body: "你的心事正漂向大海，等待另一个灵魂捡起。", createdAt: daysAgo(2, hour: 23, from: now), isRead: true, kind: .reminder)
        ]

        return AppSnapshot(
            userAlias: userAlias,
            userSignature: "在夜里寻找同频的人。",
            oceanBottles: ocean,
            thrownBottles: myThrown,
            moodPosts: posts,
            conversations: conversations,
            notifications: notifications,
            caughtBottleIDs: caughtHistory.map(\.bottle.id),
            caughtHistory: caughtHistory,
            savedBottleIDs: [caughtBottle1.id],
            diaryEntries: diaryEntries,
            unlockedAchievements: ["first_throw", "first_catch", "first_encounter", "mood_voice", "diary_keeper"],
            catchMoodFilter: .any,
            companionMinutesTotal: 18,
            lastDiaryDate: dayKey(for: now),
            moodComments: comments,
            profileAvatarEmoji: "🌙"
        )
    }

    // MARK: - Helpers

    private static let seedDiaryTexts = [
        "今天没有发生什么特别的事，但心里就是空落落的。写下来，好像好受一点。",
        "下班路上听了很久的雨声，突然没那么烦了。",
        "给未来的自己：无论现在多难，你都走过来了。",
        "今天对一个陌生人说了晚安，对方也回了一句。很小，但温暖。",
        "又失眠了。至少这里可以写点什么，不用解释。",
        "周末一个人去了咖啡馆，带了本书，坐了一下午。"
    ]

    private static let bottleTexts: [(String, BottleMood, String, Bool)] = [
        ("深夜又失眠了，想找一个同样醒着的人说说话。", .lonely, "夜航者", true),
        ("今天下班路过海边，风很大，但心里突然安静了。", .peaceful, "拾光人", false),
        ("不知道自己在等什么，也许只是在等一个回应。", .restless, "深海鱼", true),
        ("谢谢今天帮助我的陌生人，世界还是温柔的。", .grateful, "星尘客", true),
        ("雨下了整整一天，像心里放不下的那些事。", .melancholy, "晚风信使", true),
        ("希望明天会好一点，至少比今天好一点点。", .hopeful, "月光下", false),
        ("刚搬来这座城市，还没有一个可以说话的人。", .lonely, "孤岛旅人", true),
        ("加班到很晚，地铁里只有我和广告屏的光。", .melancholy, "沉默树", true),
        ("今天终于睡了一个好觉，醒来觉得生活还可以。", .peaceful, "听风者", false),
        ("有时候一句话，就能让整颗心亮起来。", .grateful, "微光里", true),
        ("想对某人说谢谢，但已经没有立场了。", .melancholy, "半醒人", true),
        ("在广场看到一条动态，突然觉得自己也被理解了。", .hopeful, "路过人间", true),
        ("陪伴模式里听潮声，竟然真的慢慢平静下来了。", .peaceful, "潮汐声", true),
        ("想找一个可以随便说话的人，不用伪装。", .lonely, "远方来信", false)
    ]

    private static let postTexts: [(String, BottleMood, String, Int)] = [
        ("有时候不是需要答案，只是需要有人听见。", .lonely, "孤岛旅人", 12),
        ("希望每个漂流瓶，都能漂到懂它的人手里。", .hopeful, "月光下", 28),
        ("孤独不是缺少人群，是缺少共鸣。", .melancholy, "沉默树", 45),
        ("今晚的月亮很亮，可惜无人分享。", .lonely, "听风者", 19),
        ("给自己泡了杯热茶，慢慢把今天放下。", .peaceful, "微光里", 33),
        ("被一句陌生人的晚安治愈了。", .grateful, "星尘客", 52),
        ("在这里发心情，比发朋友圈轻松多了。", .peaceful, "拾光人", 41),
        ("今天鼓起勇气和一个人说了话，算进步吧。", .hopeful, "路过人间", 27),
        ("有些夜晚，只需要一个「我懂」。", .melancholy, "半醒人", 38),
        ("深海里也有光，只是要游深一点才能看见。", .hopeful, "深海鱼", 64)
    ]

    private static func communityBottles(now: Date, count: Int) -> [DriftBottle] {
        bottleTexts.prefix(count).enumerated().map { index, item in
            DriftBottle(
                content: item.0,
                mood: item.1,
                authorAlias: item.2,
                createdAt: now.addingTimeInterval(-Double(1800 + index * 2700)),
                isAnonymous: item.3
            )
        }
    }

    private static func communityPosts(now: Date, count: Int) -> [MoodPost] {
        postTexts.prefix(count).enumerated().map { index, item in
            MoodPost(
                content: item.0,
                mood: item.1,
                authorAlias: item.2,
                createdAt: now.addingTimeInterval(-Double(3600 + index * 5400)),
                likeCount: item.3
            )
        }
    }

    private static func sampleComments(for posts: [MoodPost], now: Date) -> [MoodComment] {
        guard posts.count >= 2 else { return [] }
        return [
            MoodComment(postID: posts[0].id, authorAlias: "听风者", content: "抱抱你，今晚我也在。", createdAt: now.addingTimeInterval(-3000)),
            MoodComment(postID: posts[0].id, authorAlias: "微光里", content: "被听见，本身就是一种温柔。", createdAt: now.addingTimeInterval(-2400)),
            MoodComment(postID: posts[1].id, authorAlias: "拾光人", content: "坚持记录本身就很了不起。", createdAt: now.addingTimeInterval(-7200)),
            MoodComment(postID: posts[1].id, authorAlias: "深海鱼", content: "写下来会轻松一点，我也是。", createdAt: now.addingTimeInterval(-5400)),
            MoodComment(postID: posts[1].id, authorAlias: "微光里", content: "给你一点温柔回应。", createdAt: now.addingTimeInterval(-3600)),
            MoodComment(postID: posts[2].id, authorAlias: "拾光人", content: "共鸣这件事，真的很奇妙。", createdAt: now.addingTimeInterval(-8000))
        ]
    }

    private static func seedComments(for posts: [MoodPost], userAlias: String, now: Date) -> [MoodComment] {
        var comments = sampleComments(for: posts, now: now)
        if posts.count >= 7 {
            comments += [
                MoodComment(postID: posts[3].id, authorAlias: "月光下", content: "月亮同频，你并不孤单。", createdAt: daysAgo(2, hour: 20, from: now)),
                MoodComment(postID: posts[3].id, authorAlias: "深海鱼", content: "我也经常一个人看月亮。", createdAt: daysAgo(2, hour: 19, from: now)),
                MoodComment(postID: posts[4].id, authorAlias: "沉默树", content: "热茶 + 夜晚，最好的组合。", createdAt: daysAgo(3, hour: 21, from: now)),
                MoodComment(postID: posts[5].id, authorAlias: "孤岛旅人", content: "陌生人的温柔，最戳心。", createdAt: daysAgo(1, hour: 15, from: now)),
                MoodComment(postID: posts[5].id, authorAlias: userAlias, content: "谢谢，今晚被治愈了。", createdAt: daysAgo(1, hour: 14, from: now)),
                MoodComment(postID: posts[6].id, authorAlias: "听风者", content: "同感，这里让人放松。", createdAt: daysAgo(4, hour: 11, from: now))
            ]
        }
        return comments
    }

    private static func daysAgo(_ days: Int, hour: Int, from date: Date) -> Date {
        var components = DateComponents()
        components.day = -days
        components.hour = hour
        components.minute = Int.random(in: 5...45)
        return Calendar.current.date(byAdding: components, to: Calendar.current.startOfDay(for: date)) ?? date
    }

    private static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
