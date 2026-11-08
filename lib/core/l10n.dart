import 'package:flutter/widgets.dart';

/// Simple in-app translations (Arabic / French).
/// Each key maps to `[arabic, french]`.
class AppStrings {
  AppStrings._();

  static const supportedLocales = [Locale('ar'), Locale('fr')];

  static String of(String languageCode, String key) {
    final entry = _t[key];
    if (entry == null) return key;
    return languageCode == 'fr' ? entry[1] : entry[0];
  }

  static const Map<String, List<String>> _t = {
    // General
    'app_name': ['شفاءٌ للنّاس', 'Chifa Linnas'],
    'app_slogan': [
      'استشارات طبية خيرية عن بُعد',
      'Consultations médicales solidaires à distance',
    ],
    'association': [
      'جمعية عون وسند الخيرية',
      'Association caritative Aoun wa Sanad',
    ],
    'about_shifa': [
      'شفاءٌ للنّاس هي منصة رقمية خيرية تابعة لجمعية عون وسند الخيرية، تهدف إلى تقديم الاستشارات الطبية الخيرية عن بُعد وتسهيل وصول الرعاية الصحية والدعم الطبي للفئات المستهدفة بسهولة وكرامة',
      'Chifa Linnas est une plateforme numérique solidaire de l’association caritative Aoun wa Sanad. Elle propose des consultations médicales à distance et facilite l’accès aux soins et au soutien médical pour les personnes ciblées, en toute simplicité et dans la dignité.',
    ],
    'next': ['التالي', 'Suivant'],
    'back': ['رجوع', 'Retour'],
    'skip': ['تخطي', 'Passer'],
    'start': ['ابدأ الآن', 'Commencer'],
    'save': ['حفظ', 'Enregistrer'],
    'cancel': ['إلغاء', 'Annuler'],
    'confirm': ['تأكيد', 'Confirmer'],
    'send': ['إرسال', 'Envoyer'],
    'search': ['بحث...', 'Rechercher...'],
    'all': ['الكل', 'Tous'],
    'see_all': ['عرض الكل', 'Voir tout'],
    'saved': ['تم الحفظ بنجاح', 'Enregistré avec succès'],
    'required_field': ['هذا الحقل مطلوب', 'Ce champ est obligatoire'],
    'years': ['سنة', 'ans'],
    'logout': ['تسجيل الخروج', 'Déconnexion'],
    'just_now': ['الآن', "À l'instant"],
    'minutes_ago': ['منذ {n} دقيقة', 'Il y a {n} min'],
    'hours_ago': ['منذ {n} ساعة', 'Il y a {n} h'],
    'days_ago': ['منذ {n} يوم', 'Il y a {n} j'],

    // Onboarding
    'onb1_title': ['استشارة طبية مجانية', 'Consultation médicale gratuite'],
    'onb1_body': [
      'أطباء متطوعون يقرؤون فحوصك ويجيبون عن أسئلتك دون أي مقابل.',
      'Des médecins bénévoles lisent vos analyses et répondent gratuitement.',
    ],
    'onb2_title': ['ارفع فحوصك بسهولة', 'Envoyez vos analyses facilement'],
    'onb2_body': [
      'صوّر التحاليل أو الأشعة وأرسلها في خطوات بسيطة.',
      'Photographiez vos analyses ou radios et envoyez-les en quelques étapes.',
    ],
    'onb3_title': ['كن طبيباً متطوعاً', 'Devenez médecin bénévole'],
    'onb3_body': [
      'دقائق من وقتك قد تغيّر حياة مريض محتاج.',
      'Quelques minutes de votre temps peuvent changer la vie d’un patient.',
    ],

    // Role / auth
    'who_are_you': ['من أنت؟', 'Qui êtes-vous ?'],
    'choose_role': [
      'اختر نوع الحساب للمتابعة',
      'Choisissez votre type de compte',
    ],
    'role_patient': ['أنا مريض', 'Je suis patient'],
    'role_patient_desc': [
      'أريد استشارة أو قراءة فحوصي',
      'Je veux une consultation ou une lecture d’analyses',
    ],
    'role_doctor': ['أنا طبيب متطوع', 'Je suis médecin bénévole'],
    'role_doctor_desc': [
      'أريد مساعدة المرضى بخبرتي',
      'Je veux aider les patients avec mon expertise',
    ],
    'login': ['تسجيل الدخول', 'Connexion'],
    'login_welcome': ['مرحباً بعودتك', 'Bon retour'],
    'register': ['إنشاء حساب', 'Créer un compte'],
    'phone_or_email': ['رقم الهاتف أو البريد', 'Téléphone ou e-mail'],
    'password': ['كلمة المرور', 'Mot de passe'],
    'full_name': ['الاسم الكامل', 'Nom complet'],
    'phone': ['رقم الهاتف', 'Téléphone'],
    'no_account': ['ليس لديك حساب؟', 'Pas de compte ?'],
    'have_account': ['لديك حساب؟', 'Déjà un compte ?'],
    'forgot_password': ['نسيت كلمة المرور؟', 'Mot de passe oublié ?'],
    'specialty': ['التخصص', 'Spécialité'],
    'license_number': [
      'رقم التسجيل في هيئة الأطباء',
      'Numéro d’inscription à l’Ordre',
    ],
    'upload_certificate': [
      'رفع صورة الشهادة / البطاقة المهنية',
      'Joindre diplôme / carte professionnelle',
    ],
    'certificate_uploaded': ['تم إرفاق الشهادة', 'Document joint'],
    'accept_terms': [
      'أوافق على الشروط وإخلاء المسؤولية الطبية',
      'J’accepte les conditions et l’avertissement médical',
    ],
    'must_accept_terms': [
      'يجب الموافقة على الشروط',
      'Vous devez accepter les conditions',
    ],
    'doctor_review_note': [
      'سيتم مراجعة بياناتك والتحقق منها خلال 48 ساعة.',
      'Vos informations seront vérifiées sous 48 h.',
    ],

    // Specialties
    'sp_general': ['طب عام', 'Médecine générale'],
    'sp_internal': ['باطنية', 'Médecine interne'],
    'sp_pediatrics': ['أطفال', 'Pédiatrie'],
    'sp_gyneco': ['نساء وتوليد', 'Gynécologie'],
    'sp_cardio': ['قلب', 'Cardiologie'],
    'sp_derma': ['جلدية', 'Dermatologie'],
    'sp_ortho': ['عظام', 'Orthopédie'],
    'sp_endo': ['سكري وغدد', 'Endocrinologie'],
    'sp_radiology': ['أشعة', 'Radiologie'],

    // Consultation types / status / urgency
    'type_lab': ['قراءة تحاليل', 'Lecture d’analyses'],
    'type_imaging': ['قراءة أشعة', 'Lecture d’imagerie'],
    'type_general': ['استشارة عامة', 'Consultation générale'],
    'status_pending': ['في الانتظار', 'En attente'],
    'status_accepted': ['قيد المراجعة', 'En cours'],
    'status_answered': ['تم الرد', 'Répondu'],
    'status_closed': ['مغلقة', 'Clôturée'],
    'urgency_normal': ['عادي', 'Normal'],
    'urgency_soon': ['قريب', 'Bientôt'],
    'urgency_urgent': ['مستعجل', 'Urgent'],

    // Patient home
    'hello': ['مرحباً', 'Bonjour'],
    'how_feel': ['كيف تشعر اليوم؟', 'Comment allez-vous aujourd’hui ?'],
    'request_consultation': ['طلب استشارة', 'Demander une consultation'],
    'request_consultation_desc': [
      'اعرض حالتك على طبيب متطوع مجاناً',
      'Présentez votre cas à un médecin bénévole',
    ],
    'emergency_title': ['حالة طارئة؟', 'Urgence ?'],
    'emergency_body': [
      'التطبيق ليس للطوارئ. اتصل بالإسعاف فوراً.',
      'L’application n’est pas faite pour les urgences. Appelez le SAMU.',
    ],
    'call': ['اتصال', 'Appeler'],
    'quick_services': ['خدمات سريعة', 'Services rapides'],
    'volunteer_doctors': ['طبيب متطوع', 'médecins bénévoles'],
    'answered_consultations': ['استشارة مُجابة', 'consultations répondues'],
    'avg_response': ['متوسط الرد', 'délai moyen'],
    'last_consultation': ['آخر استشارة', 'Dernière consultation'],
    'health_tips': ['نصائح صحية', 'Conseils santé'],
    'tip1': ['اشرب 8 أكواب من الماء يومياً', 'Buvez 8 verres d’eau par jour'],
    'tip2': [
      'المشي 30 دقيقة يحمي قلبك',
      '30 min de marche protègent votre cœur',
    ],
    'tip3': [
      'لا تتوقف عن دوائك دون استشارة',
      'N’arrêtez pas un traitement sans avis',
    ],
    'tip4': ['افحص السكر والضغط بانتظام', 'Contrôlez glycémie et tension'],

    // Nav
    'nav_home': ['الرئيسية', 'Accueil'],
    'nav_consultations': ['استشاراتي', 'Mes consultations'],
    'nav_doctors': ['الأطباء', 'Médecins'],
    'nav_profile': ['حسابي', 'Profil'],
    'nav_dashboard': ['لوحتي', 'Tableau de bord'],
    'nav_requests': ['الطلبات', 'Demandes'],
    'nav_cases': ['حالاتي', 'Mes cas'],

    // My consultations
    'active': ['الجارية', 'En cours'],
    'completed': ['المكتملة', 'Terminées'],
    'no_consultations': [
      'لا توجد استشارات بعد',
      'Aucune consultation pour le moment',
    ],
    'no_requests': ['لا توجد طلبات حالياً', 'Aucune demande pour le moment'],

    // New consultation
    'new_consultation': ['استشارة جديدة', 'Nouvelle consultation'],
    'step_specialty': ['التخصص', 'Spécialité'],
    'step_symptoms': ['الأعراض', 'Symptômes'],
    'step_files': ['الفحوص', 'Documents'],
    'step_review': ['المراجعة', 'Vérification'],
    'choose_specialty': ['اختر التخصص المطلوب', 'Choisissez la spécialité'],
    'consultation_type': ['نوع الطلب', 'Type de demande'],
    'describe_symptoms': ['صف الأعراض بالتفصيل', 'Décrivez vos symptômes'],
    'symptoms_hint': [
      'مثال: صداع مستمر منذ أسبوع مع دوخة صباحية...',
      'Ex : maux de tête depuis une semaine avec vertiges...',
    ],
    'symptoms_duration': ['منذ متى؟', 'Depuis quand ?'],
    'dur_days': ['أيام', 'Quelques jours'],
    'dur_weeks': ['أسابيع', 'Quelques semaines'],
    'dur_months': ['أشهر', 'Quelques mois'],
    'dur_years': ['أكثر من سنة', 'Plus d’un an'],
    'urgency': ['درجة الاستعجال', 'Degré d’urgence'],
    'urgent_warning': [
      'إذا كانت حالتك خطيرة (ألم صدر، ضيق تنفس، نزيف) اتصل بالإسعاف فوراً.',
      'Si votre état est grave (douleur thoracique, essoufflement, saignement), appelez les secours.',
    ],
    'attach_files': ['أرفق التحاليل أو الأشعة', 'Joignez analyses ou radios'],
    'attach_hint': [
      'صور واضحة تساعد الطبيب على القراءة الدقيقة',
      'Des photos nettes aident le médecin',
    ],
    'camera': ['الكاميرا', 'Caméra'],
    'gallery': ['المعرض', 'Galerie'],
    'pdf_file': ['ملف PDF', 'Fichier PDF'],
    'no_files': ['لم تُرفق أي ملفات بعد', 'Aucun fichier joint'],
    'hide_name': ['إخفاء اسمي عن الطبيب', 'Masquer mon nom au médecin'],
    'hide_name_desc': [
      'سيظهر اسمك بالأحرف الأولى فقط',
      'Seules vos initiales seront visibles',
    ],
    'submit_request': ['إرسال الطلب', 'Envoyer la demande'],
    'request_sent': ['تم إرسال طلبك', 'Demande envoyée'],
    'request_sent_body': [
      'سيصلك إشعار عندما يقبل طبيب متطوع حالتك.',
      'Vous serez notifié dès qu’un médecin accepte votre cas.',
    ],
    'view_request': ['عرض الطلب', 'Voir la demande'],
    'files_count': ['ملفات مرفقة', 'fichiers joints'],

    // Consultation details
    'consultation_details': ['تفاصيل الاستشارة', 'Détails de la consultation'],
    'symptoms': ['الأعراض', 'Symptômes'],
    'attachments': ['المرفقات', 'Pièces jointes'],
    'assigned_doctor': ['الطبيب المتابع', 'Médecin assigné'],
    'doctor_reply': ['رد الطبيب', 'Réponse du médecin'],
    'findings': ['قراءة الفحوص', 'Lecture des examens'],
    'diagnosis': ['التشخيص المبدئي', 'Diagnostic préliminaire'],
    'recommendations': ['التوصيات', 'Recommandations'],
    'needs_visit': [
      'ينصح الطبيب بزيارة طبيب حضورياً',
      'Le médecin recommande une consultation en présentiel',
    ],
    'open_chat': ['محادثة الطبيب', 'Discuter avec le médecin'],
    'rate_doctor': ['قيّم الطبيب', 'Évaluer le médecin'],
    'rate_title': ['ما تقييمك للاستشارة؟', 'Votre avis sur la consultation ?'],
    'thanks_rating': ['شكراً لتقييمك!', 'Merci pour votre avis !'],
    'your_rating': ['تقييمك', 'Votre note'],
    'waiting_doctor': [
      'طلبك في انتظار طبيب متطوع. شكراً لصبرك.',
      'Votre demande attend un médecin bénévole. Merci de votre patience.',
    ],
    'tl_sent': ['أُرسل الطلب', 'Envoyée'],
    'tl_accepted': ['قبله طبيب', 'Acceptée'],
    'tl_answered': ['تم الرد', 'Répondue'],

    // Doctors list
    'our_doctors': ['أطباؤنا المتطوعون', 'Nos médecins bénévoles'],
    'verified_doctor': ['طبيب موثّق', 'Médecin vérifié'],
    'experience': ['خبرة', 'Expérience'],
    'consultations': ['استشارة', 'consultations'],
    'available_now': ['متاح الآن', 'Disponible'],
    'unavailable': ['غير متاح', 'Indisponible'],
    'join_as_doctor': [
      'هل أنت طبيب؟ انضم إلينا متطوعاً',
      'Vous êtes médecin ? Rejoignez-nous',
    ],

    // Profile / health profile
    'health_profile': ['ملفي الصحي', 'Mon dossier santé'],
    'age': ['العمر', 'Âge'],
    'gender': ['الجنس', 'Sexe'],
    'male': ['ذكر', 'Homme'],
    'female': ['أنثى', 'Femme'],
    'blood_type': ['فصيلة الدم', 'Groupe sanguin'],
    'chronic_diseases': ['الأمراض المزمنة', 'Maladies chroniques'],
    'cd_diabetes': ['سكري', 'Diabète'],
    'cd_hypertension': ['ضغط', 'Hypertension'],
    'cd_asthma': ['ربو', 'Asthme'],
    'cd_heart': ['أمراض قلب', 'Maladie cardiaque'],
    'cd_kidney': ['أمراض كلى', 'Maladie rénale'],
    'allergies': ['الحساسية', 'Allergies'],
    'current_medications': ['الأدوية الحالية', 'Traitements actuels'],
    'none': ['لا يوجد', 'Aucun'],
    'notifications': ['الإشعارات', 'Notifications'],
    'settings': ['الإعدادات', 'Paramètres'],
    'disclaimer': ['إخلاء المسؤولية الطبية', 'Avertissement médical'],
    'about': ['عن التطبيق', 'À propos'],
    'contact_us': ['تواصل معنا', 'Nous contacter'],
    'language': ['اللغة', 'Langue'],
    'theme': ['المظهر', 'Thème'],
    'theme_light': ['فاتح', 'Clair'],
    'theme_dark': ['داكن', 'Sombre'],
    'theme_system': ['تلقائي', 'Auto'],
    'version': ['الإصدار', 'Version'],

    // Doctor side
    'doctor_greeting': ['أهلاً د.', 'Bonjour Dr'],
    'thank_you_doctor': [
      'شكراً لعطائك! ساعدت {n} مريضاً هذا الشهر.',
      'Merci ! Vous avez aidé {n} patients ce mois-ci.',
    ],
    'helped_patients': ['مريض ساعدته', 'patients aidés'],
    'rating': ['التقييم', 'Note'],
    'waiting_in_specialty': ['طلب في تخصصك', 'demandes dans votre spécialité'],
    'available_for_cases': ['متاح لاستقبال الحالات', 'Disponible pour des cas'],
    'urgent_requests': ['طلبات مستعجلة', 'Demandes urgentes'],
    'request_details': ['تفاصيل الطلب', 'Détails de la demande'],
    'patient_info': ['معلومات المريض', 'Informations du patient'],
    'accept_case': ['قبول الحالة', 'Accepter le cas'],
    'case_accepted': [
      'تم قبول الحالة. يمكنك الآن كتابة الرد.',
      'Cas accepté. Vous pouvez maintenant répondre.',
    ],
    'write_reply': ['كتابة الرد', 'Rédiger la réponse'],
    'findings_hint': [
      'ماذا تُظهر التحاليل أو الأشعة؟',
      'Que montrent les analyses ou l’imagerie ?',
    ],
    'diagnosis_hint': ['التشخيص المحتمل', 'Diagnostic probable'],
    'recommendations_hint': [
      'نصائح، فحوص إضافية، نمط حياة...',
      'Conseils, examens complémentaires, hygiène de vie...',
    ],
    'reply_sent': ['تم إرسال الرد للمريض', 'Réponse envoyée au patient'],
    'in_progress': ['قيد المتابعة', 'En cours'],
    'answered': ['تم الرد', 'Répondues'],
    'availability_hours': ['أوقات التطوع', 'Disponibilités'],
    'professional_profile': ['ملفي المهني', 'Profil professionnel'],
    'patient_label': ['المريض', 'Patient'],
    'tap_to_preview': ['اضغط للمعاينة', 'Toucher pour voir'],
    'preview_placeholder': [
      'معاينة الملف (ستعمل عند ربط التطبيق بالخادم)',
      'Aperçu du fichier (disponible après connexion au serveur)',
    ],
    'accepted_by_other': [
      'هذه الحالة مع طبيب آخر',
      'Ce cas est suivi par un autre médecin',
    ],

    // Chat
    'chat': ['المحادثة', 'Discussion'],
    'type_message': ['اكتب رسالتك...', 'Écrivez votre message...'],
    'chat_notice': [
      'المحادثة للمتابعة فقط ولا تغني عن الكشف الحضوري.',
      'La discussion sert au suivi et ne remplace pas une consultation.',
    ],

    // Disclaimer
    'disclaimer_body': [
      'الاستشارات المقدمة عبر تطبيق شفاءٌ للنّاس إرشادية وتطوعية، ولا تغني عن الكشف الطبي الحضوري أو العلاج في المستشفى.\n\n'
          '• التطبيق ليس مخصصاً لحالات الطوارئ. في الحالات الخطيرة اتصل بالإسعاف فوراً.\n\n'
          '• لا تتوقف عن أي دواء أو تغيّر جرعته دون الرجوع إلى طبيبك المعالج.\n\n'
          '• يتم التحقق من هوية الأطباء المتطوعين قبل قبولهم في المنصة.\n\n'
          '• بياناتك وفحوصك سرية، ولا يطّلع عليها إلا الطبيب الذي يتابع حالتك.',
      'Les consultations proposées sur Chifa Linnas sont indicatives et bénévoles. Elles ne remplacent pas un examen médical en présentiel ni une prise en charge hospitalière.\n\n'
          '• L’application n’est pas destinée aux urgences. En cas de danger, appelez immédiatement les secours.\n\n'
          '• N’arrêtez ni ne modifiez aucun traitement sans l’avis de votre médecin traitant.\n\n'
          '• L’identité des médecins bénévoles est vérifiée avant leur admission.\n\n'
          '• Vos données et examens sont confidentiels et visibles uniquement par le médecin qui suit votre cas.',
    ],
  };
}

extension TrX on BuildContext {
  String tr(String key, {Map<String, Object>? args}) {
    var value = AppStrings.of(Localizations.localeOf(this).languageCode, key);
    args?.forEach((k, v) => value = value.replaceAll('{$k}', '$v'));
    return value;
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return tr('just_now');
    if (diff.inHours < 1) return tr('minutes_ago', args: {'n': diff.inMinutes});
    if (diff.inDays < 1) return tr('hours_ago', args: {'n': diff.inHours});
    return tr('days_ago', args: {'n': diff.inDays});
  }
}
