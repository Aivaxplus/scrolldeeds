//
//  ShieldVerses.swift
//  ScrollDeedsShield
//
//  A different ayah and reflection question each time the lock screen appears.
//

import Foundation

struct ShieldVerse {
    let text: String
    let reference: String
    let reflection: String
}

enum ShieldVerses {
    private static let indexKey = "shieldVerseIndex"
    private static let appGroupID = "group.com.scrolldeeds.app"

    static func current(language: String, advance: Bool) -> ShieldVerse {
        let defaults = UserDefaults(suiteName: appGroupID)
        var index = defaults?.integer(forKey: indexKey) ?? 0
        if advance {
            index = (index + 1) % entries.count
            defaults?.set(index, forKey: indexKey)
        }
        let entry = entries[index % entries.count]
        let local = entry.text[language] ?? entry.text["en"]!
        return ShieldVerse(
            text: local.ayah,
            reference: "\(quranWord[language] ?? "Qur’an") \(entry.ref)",
            reflection: local.question
        )
    }

    private static let quranWord: [String: String] = [
        "en": "Qur’an", "nl": "Koran", "es": "Corán", "de": "Koran",
        "fr": "Coran", "ru": "Коран", "ar": "القرآن"
    ]

    private struct Entry {
        let ref: String
        let text: [String: (ayah: String, question: String)]
    }

    private static let entries: [Entry] = [
        Entry(ref: "13:28", text: [
            "en": ("Verily, in the remembrance of Allah do hearts find rest.", "What is your heart looking for right now?"),
            "nl": ("Voorwaar, in het gedenken van Allah vinden de harten rust.", "Wat zoekt je hart op dit moment?"),
            "es": ("En verdad, con el recuerdo de Allah se tranquilizan los corazones.", "¿Qué busca tu corazón ahora mismo?"),
            "de": ("Wahrlich, im Gedenken Allahs finden die Herzen Ruhe.", "Wonach sucht dein Herz gerade?"),
            "fr": ("C’est par l’évocation d’Allah que les cœurs se tranquillisent.", "Que cherche ton cœur en ce moment ?"),
            "ru": ("Воистину, поминанием Аллаха утешаются сердца.", "Что сейчас ищет твоё сердце?"),
            "ar": ("أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", "ما الذي يبحث عنه قلبك الآن؟"),
        ]),
        Entry(ref: "2:152", text: [
            "en": ("So remember Me; I will remember you.", "When did you last think of Allah today?"),
            "nl": ("Gedenk Mij, dan zal Ik jullie gedenken.", "Wanneer dacht je vandaag voor het laatst aan Allah?"),
            "es": ("Recordadme, que Yo os recordaré.", "¿Cuándo pensaste en Allah por última vez hoy?"),
            "de": ("Gedenkt Meiner, so gedenke Ich euer.", "Wann hast du heute zuletzt an Allah gedacht?"),
            "fr": ("Souvenez-vous de Moi, Je Me souviendrai de vous.", "Quand as-tu pensé à Allah pour la dernière fois aujourd’hui ?"),
            "ru": ("Поминайте Меня, и Я буду помнить о вас.", "Когда ты сегодня в последний раз вспоминал Аллаха?"),
            "ar": ("فَاذْكُرُونِي أَذْكُرْكُمْ", "متى ذكرت الله آخر مرة اليوم؟"),
        ]),
        Entry(ref: "2:186", text: [
            "en": ("I am near. I respond to the call of the one who calls upon Me.", "What would you like to ask Allah for right now?"),
            "nl": ("Ik ben nabij. Ik verhoor de smeekbede van wie Mij aanroept.", "Waar wil je Allah nu om vragen?"),
            "es": ("Estoy cerca. Respondo a la súplica de quien Me invoca.", "¿Qué te gustaría pedirle a Allah ahora?"),
            "de": ("Ich bin nahe. Ich erhöre das Bittgebet dessen, der Mich anruft.", "Worum möchtest du Allah jetzt bitten?"),
            "fr": ("Je suis proche. Je réponds à l’appel de celui qui M’invoque.", "Que voudrais-tu demander à Allah maintenant ?"),
            "ru": ("Я близок и отвечаю на мольбу молящегося, когда он взывает ко Мне.", "О чём ты хочешь попросить Аллаха сейчас?"),
            "ar": ("فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ", "ماذا تريد أن تسأل الله الآن؟"),
        ]),
        Entry(ref: "50:16", text: [
            "en": ("We are closer to him than his jugular vein.", "If you spoke to Allah now, what would you say?"),
            "nl": ("Wij zijn hem nader dan zijn halsslagader.", "Als je nu tot Allah sprak, wat zou je zeggen?"),
            "es": ("Estamos más cerca de él que su vena yugular.", "Si hablaras ahora con Allah, ¿qué le dirías?"),
            "de": ("Wir sind ihm näher als seine Halsschlagader.", "Wenn du jetzt mit Allah sprechen würdest, was würdest du sagen?"),
            "fr": ("Nous sommes plus près de lui que sa veine jugulaire.", "Si tu parlais à Allah maintenant, que Lui dirais-tu ?"),
            "ru": ("Мы ближе к нему, чем яремная вена.", "Если бы ты сейчас обратился к Аллаху, что бы ты сказал?"),
            "ar": ("وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ", "لو ناجيت الله الآن، ماذا ستقول؟"),
        ]),
        Entry(ref: "59:18", text: [
            "en": ("Let every soul look to what it has sent ahead for tomorrow.", "What are you sending ahead with this minute?"),
            "nl": ("Laat iedere ziel kijken wat zij vooruitstuurt voor morgen.", "Wat stuur je vooruit met deze minuut?"),
            "es": ("Que cada alma mire lo que ha enviado por delante para mañana.", "¿Qué envías por delante con este minuto?"),
            "de": ("Jede Seele soll schauen, was sie für morgen vorausschickt.", "Was schickst du mit dieser Minute voraus?"),
            "fr": ("Que chaque âme considère ce qu’elle a préparé pour demain.", "Que prépares-tu avec cette minute ?"),
            "ru": ("Пусть каждая душа посмотрит, что она приготовила на завтра.", "Что ты отправляешь вперёд этой минутой?"),
            "ar": ("وَلْتَنظُرْ نَفْسٌ مَّا قَدَّمَتْ لِغَدٍ", "ماذا تقدّم لغدك بهذه الدقيقة؟"),
        ]),
        Entry(ref: "39:53", text: [
            "en": ("Do not despair of the mercy of Allah.", "What would you like to begin again today?"),
            "nl": ("Wanhoop niet aan de genade van Allah.", "Waar wil je vandaag opnieuw mee beginnen?"),
            "es": ("No desesperéis de la misericordia de Allah.", "¿Qué te gustaría empezar de nuevo hoy?"),
            "de": ("Verliert nicht die Hoffnung auf Allahs Barmherzigkeit.", "Womit möchtest du heute neu anfangen?"),
            "fr": ("Ne désespérez pas de la miséricorde d’Allah.", "Qu’aimerais-tu recommencer aujourd’hui ?"),
            "ru": ("Не отчаивайтесь в милости Аллаха.", "Что ты хочешь начать заново сегодня?"),
            "ar": ("لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ", "بماذا تريد أن تبدأ من جديد اليوم؟"),
        ]),
        Entry(ref: "94:6", text: [
            "en": ("Indeed, with hardship comes ease.", "What weighs on you today — have you told Allah about it?"),
            "nl": ("Voorwaar, met de moeilijkheid komt verlichting.", "Wat weegt zwaar vandaag — heb je het al aan Allah verteld?"),
            "es": ("En verdad, con la dificultad viene la facilidad.", "¿Qué te pesa hoy? ¿Ya se lo has contado a Allah?"),
            "de": ("Wahrlich, mit der Schwierigkeit kommt Erleichterung.", "Was belastet dich heute — hast du es Allah schon erzählt?"),
            "fr": ("Certes, avec la difficulté vient la facilité.", "Qu’est-ce qui te pèse aujourd’hui — l’as-tu confié à Allah ?"),
            "ru": ("Воистину, за тягостью наступает облегчение.", "Что тяготит тебя сегодня — ты уже рассказал об этом Аллаху?"),
            "ar": ("إِنَّ مَعَ الْعُسْرِ يُسْرًا", "ما الذي يثقل عليك اليوم؟ هل أخبرت الله به؟"),
        ]),
        Entry(ref: "65:3", text: [
            "en": ("Whoever puts their trust in Allah, He is enough for them.", "What can you leave in Allah’s hands today?"),
            "nl": ("Wie op Allah vertrouwt, Hij is hem genoeg.", "Wat kun je vandaag aan Allah overlaten?"),
            "es": ("A quien confía en Allah, Él le basta.", "¿Qué puedes dejar hoy en manos de Allah?"),
            "de": ("Wer auf Allah vertraut, dem genügt Er.", "Was kannst du heute Allah überlassen?"),
            "fr": ("Quiconque place sa confiance en Allah, Il lui suffit.", "Que peux-tu confier à Allah aujourd’hui ?"),
            "ru": ("Кто уповает на Аллаха, тому достаточно Его.", "Что ты можешь сегодня доверить Аллаху?"),
            "ar": ("وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ", "ما الذي يمكنك أن تتركه لله اليوم؟"),
        ]),
        Entry(ref: "87:16–17", text: [
            "en": ("You prefer the life of this world, while the Hereafter is better and more lasting.", "What will remain of what you were about to watch?"),
            "nl": ("Jullie verkiezen het leven van deze wereld, terwijl het Hiernamaals beter en blijvender is.", "Wat blijft er over van wat je nu wilde gaan zien?"),
            "es": ("Preferís la vida de este mundo, pero la otra vida es mejor y más duradera.", "¿Qué quedará de lo que ibas a ver?"),
            "de": ("Ihr zieht das diesseitige Leben vor, doch das Jenseits ist besser und beständiger.", "Was bleibt von dem, was du gerade sehen wolltest?"),
            "fr": ("Vous préférez la vie de ce monde, alors que l’au-delà est meilleur et plus durable.", "Que restera-t-il de ce que tu allais regarder ?"),
            "ru": ("Вы предпочитаете мирскую жизнь, хотя Последняя жизнь лучше и долговечнее.", "Что останется от того, что ты собирался посмотреть?"),
            "ar": ("بَلْ تُؤْثِرُونَ الْحَيَاةَ الدُّنْيَا وَالْآخِرَةُ خَيْرٌ وَأَبْقَىٰ", "ماذا سيبقى مما كنت تنوي مشاهدته؟"),
        ]),
        Entry(ref: "57:16", text: [
            "en": ("Has the time not come for the hearts of the believers to humble themselves at the remembrance of Allah?", "What would you do now if your heart were fully with Allah?"),
            "nl": ("Is het niet tijd dat de harten van de gelovigen nederig worden bij het gedenken van Allah?", "Wat zou je nu doen als je hart helemaal bij Allah was?"),
            "es": ("¿No ha llegado el momento de que los corazones de los creyentes se humillen ante el recuerdo de Allah?", "¿Qué harías ahora si tu corazón estuviera por completo con Allah?"),
            "de": ("Ist es nicht an der Zeit, dass die Herzen der Gläubigen demütig werden beim Gedenken Allahs?", "Was würdest du jetzt tun, wenn dein Herz ganz bei Allah wäre?"),
            "fr": ("Le moment n’est-il pas venu pour les croyants que leurs cœurs s’humilient à l’évocation d’Allah ?", "Que ferais-tu maintenant si ton cœur était entièrement avec Allah ?"),
            "ru": ("Разве не пришло время, чтобы сердца верующих смирились при поминании Аллаха?", "Что бы ты сделал сейчас, если бы твоё сердце было полностью с Аллахом?"),
            "ar": ("أَلَمْ يَأْنِ لِلَّذِينَ آمَنُوا أَن تَخْشَعَ قُلُوبُهُمْ لِذِكْرِ اللَّهِ", "ماذا كنت ستفعل الآن لو كان قلبك كله مع الله؟"),
        ]),
        Entry(ref: "20:14", text: [
            "en": ("Establish prayer for My remembrance.", "When is your next prayer — are you ready for it?"),
            "nl": ("Verricht het gebed om Mij te gedenken.", "Wanneer is je volgende gebed — ben je er klaar voor?"),
            "es": ("Establece la oración para recordarme.", "¿Cuándo es tu próxima oración? ¿Estás listo para ella?"),
            "de": ("Verrichte das Gebet, um Meiner zu gedenken.", "Wann ist dein nächstes Gebet — bist du bereit dafür?"),
            "fr": ("Accomplis la prière pour te souvenir de Moi.", "Quand est ta prochaine prière — es-tu prêt ?"),
            "ru": ("Совершай намаз, чтобы поминать Меня.", "Когда твой следующий намаз — ты готов к нему?"),
            "ar": ("وَأَقِمِ الصَّلَاةَ لِذِكْرِي", "متى صلاتك القادمة؟ هل أنت مستعد لها؟"),
        ]),
        Entry(ref: "3:191", text: [
            "en": ("Those who remember Allah standing, sitting, and lying on their sides.", "Where in your day can Allah have a place right now?"),
            "nl": ("Zij die Allah gedenken, staand, zittend en liggend op hun zij.", "Waar in je dag kan Allah nu een plek krijgen?"),
            "es": ("Los que recuerdan a Allah de pie, sentados y recostados.", "¿Dónde puede tener Allah un lugar en tu día ahora mismo?"),
            "de": ("Die Allahs gedenken im Stehen, im Sitzen und auf der Seite liegend.", "Wo kann Allah jetzt einen Platz in deinem Tag bekommen?"),
            "fr": ("Ceux qui évoquent Allah debout, assis et couchés sur le côté.", "Où Allah peut-Il avoir une place dans ta journée maintenant ?"),
            "ru": ("Те, которые поминают Аллаха стоя, сидя и лёжа на боку.", "Где в твоём дне сейчас может найтись место для Аллаха?"),
            "ar": ("الَّذِينَ يَذْكُرُونَ اللَّهَ قِيَامًا وَقُعُودًا وَعَلَىٰ جُنُوبِهِمْ", "أين يمكن أن يكون لله مكان في يومك الآن؟"),
        ]),
    ]
}
