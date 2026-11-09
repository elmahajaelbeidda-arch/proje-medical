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
    'app_name': ['شِفاءٌ لِلنّاس', 'Chifa Linnas'],
    'app_slogan': [
      'استشارات طبية خيرية عن بُعد',
      'Consultations médicales solidaires à distance',
    ],
    'association': [
      'جمعية عون وسند الخيرية',
      'Association caritative Aoun wa Sanad',
    ],
    'about_shifa': [
      'شِفاءٌ لِلنّاس هي منصة رقمية خيرية تابعة لجمعية عون وسند الخيرية، تهدف إلى تقديم الاستشارات الطبية الخيرية عن بُعد وتسهيل وصول الرعاية الصحية والدعم الطبي للفئات المستهدفة بسهولة وكرامة',
      'Chifa Linnas est une plateforme numérique solidaire de l’association caritative Aoun wa Sanad. Elle propose des consultations médicales à distance et facilite l’accès aux soins et au soutien médical pour les personnes ciblées, en toute simplicité et dans la dignité.',
    ],
    'app_tagline': ['تطبيق خيري طبي', 'Application médicale solidaire'],
    // ID card + SMS verification
    'id_card': ['بطاقة التعريف الوطنية', 'Carte d’identité nationale'],
    'id_number': ['رقم بطاقة التعريف الوطنية', 'Numéro de la carte d’identité'],
    'id_number_invalid': [
      'رقم غير صالح (من 9 إلى 18 رقماً)',
      'Numéro invalide (9 à 18 chiffres)',
    ],
    'id_front': ['الوجه الأمامي', 'Recto'],
    'id_back': ['الوجه الخلفي', 'Verso'],
    'id_upload_hint': [
      'صوّر بطاقة التعريف بوضوح من الوجهين',
      'Photographiez clairement les deux faces de la carte',
    ],
    'id_photos_required': [
      'يرجى رفع صورتي بطاقة التعريف',
      'Veuillez joindre les deux faces de la carte',
    ],
    'id_privacy': [
      'بياناتك سرية وتُستخدم فقط للتحقق من هويتك',
      'Vos données sont confidentielles et servent uniquement à vérifier votre identité',
    ],
    'tap_to_add': ['اضغط للإضافة', 'Toucher pour ajouter'],
    'phone_invalid': ['رقم هاتف غير صالح', 'Numéro de téléphone invalide'],
    'verify_phone': ['التحقق من رقم الهاتف', 'Vérification du téléphone'],
    'code_sent': [
      'أرسلنا رمز تحقق من 6 أرقام إلى الرقم',
      'Nous avons envoyé un code à 6 chiffres au',
    ],
    'enter_code': ['أدخل رمز التحقق', 'Saisissez le code de vérification'],
    'demo_code': [
      'نسخة تجريبية: الرمز هو 123456',
      'Version de démonstration : le code est 123456',
    ],
    'wrong_code': ['الرمز غير صحيح', 'Code incorrect'],
    'resend_code': ['إعادة إرسال الرمز', 'Renvoyer le code'],
    'resend_in': ['إعادة الإرسال بعد {n} ثانية', 'Renvoyer dans {n} s'],
    'code_resent': ['تم إرسال رمز جديد', 'Nouveau code envoyé'],
    'verify': ['تحقق', 'Vérifier'],
    'verified': ['موثّق', 'Vérifié'],
    'phone_verified': ['تم التحقق من رقمك بنجاح', 'Numéro vérifié avec succès'],

    // Files
    'file_category': ['نوع المرفق', 'Type de document'],
    'cat_exam': ['فحص طبي', 'Examen médical'],
    'cat_lab': ['تحليل', 'Analyse'],
    'cat_prescription': ['وصفة طبية', 'Ordonnance'],
    'cat_other': ['أخرى', 'Autre'],
    'file_too_large': ['الملف أكبر من 10 ميغابايت', 'Le fichier dépasse 10 Mo'],
    'pick_failed': ['تعذّر فتح الملف', 'Impossible d’ouvrir le fichier'],
    'files_added': ['تمت إضافة {n} ملف', '{n} fichier(s) ajouté(s)'],
    'file_types_hint': [
      'صور (JPG، PNG) أو PDF — حتى 10 ميغابايت للملف',
      'Images (JPG, PNG) ou PDF — 10 Mo max par fichier',
    ],

    // Voice
    'voice_note': ['رسالة صوتية', 'Message vocal'],
    'voice_hint': [
      'سجّل رسالة صوتية تشرح فيها حالتك واحتياجاتك (اختياري)',
      'Enregistrez un message vocal pour expliquer votre état et vos besoins (facultatif)',
    ],
    'tap_to_record': ['اضغط للتسجيل', 'Appuyez pour enregistrer'],
    'recording': ['جارٍ التسجيل...', 'Enregistrement...'],
    'stop': ['إيقاف', 'Arrêter'],
    'delete': ['حذف', 'Supprimer'],
    'record_again': ['إعادة التسجيل', 'Réenregistrer'],
    'mic_denied': [
      'لم يُسمح باستخدام الميكروفون. فعّله من إعدادات المتصفح أو الهاتف.',
      'Accès au micro refusé. Activez-le dans les réglages.',
    ],
    'record_failed': [
      'تعذّر بدء التسجيل',
      'Impossible de démarrer l’enregistrement',
    ],
    'max_duration': ['الحد الأقصى 3 دقائق', 'Durée max : 3 minutes'],
    'demo_audio': [
      'تسجيل تجريبي (غير قابل للتشغيل)',
      'Enregistrement de démonstration (non lisible)',
    ],
    'voice_message': ['🎤 رسالة صوتية', '🎤 Message vocal'],
    'send_voice': ['إرسال التسجيل', 'Envoyer l’enregistrement'],
    // Voice search
    'voice_search': ['البحث الصوتي', 'Recherche vocale'],
    'voice_search_listening': ['تحدّث الآن...', 'Parlez maintenant...'],
    'voice_search_example_doctor': [
      'مثلاً: «طبيب قلب في الدار البيضاء» أو «أطفال»',
      'Ex : « cardiologue à Casablanca » ou « pédiatrie »',
    ],
    'voice_search_example_request': [
      'مثلاً: «تحليل دم» أو «سعال»',
      'Ex : « analyse de sang » ou « toux »',
    ],
    'voice_search_unavailable': [
      'البحث الصوتي غير مدعوم في هذا المتصفح. جرّب Chrome أو Safari.',
      'Recherche vocale non prise en charge ici. Essayez Chrome ou Safari.',
    ],
    'search_doctors': [
      'ابحث بالاسم أو التخصص أو المدينة',
      'Nom, spécialité ou ville',
    ],
    'search_requests': ['ابحث في الأعراض أو التخصص', 'Symptômes ou spécialité'],
    'no_results': ['لا توجد نتائج لـ «{q}»', 'Aucun résultat pour « {q} »'],
    'clear': ['مسح', 'Effacer'],
    'voice_search_error': [
      'لم نتمكن من فهم الكلام. تحدّث بوضوح وحاول مرة أخرى.',
      'Parole non reconnue. Parlez distinctement et réessayez.',
    ],
    // Blood donation
    'blood_donation': ['التبرع بالدم', 'Don de sang'],
    'nav_blood': ['تبرع بالدم', 'Don de sang'],
    'my_donor_card': ['بطاقتي كمتبرع', 'Ma carte de donneur'],
    'edit': ['تعديل', 'Modifier'],
    'blood_requests': ['طلبات الدم', 'Demandes de sang'],
    'fulfilled': ['تمّ تأمينه', 'Satisfaite'],
    'units_n': ['{n} وحدة', '{n} poche(s)'],
    'units_needed': ['عدد الوحدات (الأكياس)', 'Nombre de poches'],
    'hospital': ['المستشفى', 'Hôpital'],
    'city': ['المدينة', 'Ville'],
    'patient_name': ['اسم المريض', 'Nom du patient'],
    'blood_type_needed': ['الفصيلة المطلوبة', 'Groupe sanguin demandé'],
    'urgent_request': ['طلب مستعجل', 'Demande urgente'],
    'urgent_request_desc': [
      'عملية أو نزيف أو حالة حرجة خلال 24 ساعة',
      'Opération, hémorragie ou cas critique sous 24 h',
    ],
    'contact_method': ['وسيلة التواصل المفضلة', 'Moyen de contact préféré'],
    'contact_call': ['اتصال', 'Appel'],
    'contact_whatsapp': ['واتساب', 'WhatsApp'],
    'contact_sms': ['رسالة SMS', 'SMS'],
    'sms_short': ['SMS', 'SMS'],
    'note_optional': ['ملاحظة (اختياري)', 'Remarque (facultatif)'],
    'submit_blood_request': ['نشر الطلب', 'Publier la demande'],
    'blood_request_posted': [
      'تم نشر طلبك. هؤلاء المتبرعون يناسبون الفصيلة المطلوبة.',
      'Demande publiée. Voici les donneurs compatibles.',
    ],
    'request_blood': ['طلب دم', 'Demande de sang'],
    'matching_donors': ['المتبرعون المناسبون', 'Donneurs compatibles'],
    'matching_count': ['{n} متبرع متوافق', '{n} donneur(s) compatible(s)'],
    'no_matching_donors': [
      'لا يوجد متبرع متوافق متاح حالياً. سيظهر طلبك للمتبرعين عند تسجيلهم.',
      'Aucun donneur compatible disponible pour le moment.',
    ],
    'same_city': ['نفس المدينة', 'Même ville'],
    'exact_type': ['نفس الفصيلة', 'Même groupe'],
    'compatible': ['متوافق', 'Compatible'],
    'mark_fulfilled': ['تمّ تأمين الدم', 'Sang obtenu'],
    'marked_fulfilled': [
      'الحمد لله! أُغلق الطلب.',
      'Demande clôturée. Prompt rétablissement !',
    ],
    'register_donor': ['التسجيل كمتبرع', 'Inscription donneur'],
    'save_donor': ['حفظ بياناتي', 'Enregistrer'],
    'last_donation': ['تاريخ آخر تبرع', 'Date du dernier don'],
    'never_donated': [
      'لم أتبرع من قبل / لا أتذكر',
      'Jamais donné / je ne sais pas',
    ],
    'available_to_donate': ['متاح للتبرع', 'Disponible pour donner'],
    'share_contact_consent': [
      'أوافق على أن تتواصل معي لجنة التبرع عند الحاجة إلى فصيلتي',
      'J’accepte que le comité me contacte si mon groupe est recherché',
    ],
    'share_contact_required': [
      'الموافقة مطلوبة ليتمكن المحتاجون من التواصل معك',
      'Ce consentement est nécessaire pour être contacté',
    ],
    'next_eligible': [
      'يمكنك التبرع مجدداً بعد {date}',
      'Prochain don possible le {date}',
    ],
    'eligible_now': ['يمكنك التبرع الآن', 'Vous pouvez donner'],
    'donor_saved': [
      'تم حفظ بياناتك كمتبرع. شكراً لك ❤',
      'Profil de donneur enregistré. Merci ❤',
    ],
    'receives_from': ['يستقبل من', 'Reçoit de'],
    'blood_privacy': [
      'بيانات المتبرعين سرية: لا يطّلع عليها إلا لجنة التبرع، ولا تُعرض على المستخدمين الآخرين.',
      'Les données des donneurs sont confidentielles : seul le comité y a accès.',
    ],
    'your_request': ['طلبك', 'Votre demande'],
    // Blood donation: committee, privacy, personal info
    'role_committee': ['لجنة التبرع', 'Comité du don'],
    'committee_login': ['دخول لجنة التبرع', 'Accès comité du don'],
    'committee_title': ['لجنة التبرع', 'Comité'],
    'committee_only': [
      'هذه المعلومات لا تظهر إلا للجنة التبرع',
      'Informations visibles par le comité uniquement',
    ],
    'committee_will_contact': [
      'ستتواصل معك لجنة التبرع لترتيب التبرع. بياناتك لا تُعرض على أحد.',
      'Le comité vous contactera pour organiser le don. Vos données restent confidentielles.',
    ],
    'committee_reviews_request': [
      'تراجع لجنة التبرع طلبك وتربطه بمتبرعين مناسبين، ثم تتصل بك.',
      'Le comité étudie votre demande, la relie à des donneurs compatibles puis vous appelle.',
    ],
    'status_submitted': ['جديد', 'Nouvelle'],
    'status_inProgress': ['قيد المعالجة', 'En traitement'],
    'status_matched': ['تم الربط بمتبرعين', 'Donneurs trouvés'],
    'status_fulfilled': ['تمّ تأمين الدم', 'Sang obtenu'],
    'status_cancelled': ['ملغى', 'Annulée'],
    'request_status': ['حالة الطلب', 'Statut de la demande'],
    'cancel_request': ['إلغاء الطلب', 'Annuler la demande'],
    'linked_donors': ['المتبرعون المرتبطون', 'Donneurs liés'],
    'linked_n': ['{n} مرتبط', '{n} lié(s)'],
    'suggested_donors': ['متبرعون مقترحون', 'Donneurs suggérés'],
    'link': ['ربط', 'Lier'],
    'unlink': ['إلغاء الربط', 'Retirer'],
    'donor_linked': ['تم ربط المتبرع بالطلب', 'Donneur lié à la demande'],
    'requester': ['صاحب الطلب', 'Demandeur'],
    'requester_name': ['اسم صاحب الطلب', 'Nom du demandeur'],
    'relation': ['صلته بالمريض', 'Lien avec le patient'],
    'relation_self': ['المريض نفسه', 'Le patient lui-même'],
    'relation_family': ['أحد أفراد العائلة', 'Un proche'],
    'relation_other': ['آخر', 'Autre'],
    'donors': ['المتبرعون', 'Donneurs'],
    'requests': ['الطلبات', 'Demandes'],
    'new_requests': ['طلب جديد', 'nouvelle(s)'],
    'available_donors': ['متبرع متاح', 'donneurs dispo.'],
    'secured': ['تم تأمينه', 'satisfaites'],
    'donor_kind': ['أنت', 'Vous êtes'],
    'kind_patient': ['مريض', 'Patient'],
    'kind_doctor': ['طبيب', 'Médecin'],
    'kind_other': ['متبرع دون حساب', 'Donneur sans compte'],
    'age_years': ['العمر (بالسنوات)', 'Âge (ans)'],
    'age_out_of_range': [
      'يجب أن يكون عمر المتبرع بين 18 و65 سنة',
      'Le donneur doit avoir entre 18 et 65 ans',
    ],
    'health_declaration': [
      'أصرّح أن وزني أكثر من 50 كغ وأنني بصحة جيدة',
      'Je déclare peser plus de 50 kg et être en bonne santé',
    ],
    'health_declaration_required': [
      'هذا التصريح مطلوب للتسجيل كمتبرع',
      'Cette déclaration est requise',
    ],
    'personal_info': ['المعلومات الشخصية', 'Informations personnelles'],
    'unavailable_now': ['غير متاح حالياً', 'Indisponible'],
    'too_soon': ['تبرع مؤخراً', 'Don récent'],
    'all_statuses': ['كل الحالات', 'Tous'],
    'search_donors_hint': [
      'ابحث بالاسم أو الرمز أو المدينة',
      'Nom, code ou ville',
    ],
    'registered_on': ['سُجّل في {date}', 'Inscrit le {date}'],
    'donor_code': ['رمز المتبرع', 'Code donneur'],
    'request_code': ['رمز الطلب', 'Code demande'],
    // Blood donation: donors only + committee review
    'donor_section_intro': [
      'سجّل كمتبرع بالدم. تراجع لجنة التبرع تسجيلك، ثم تتواصل معك عند الحاجة إلى فصيلتك.',
      'Inscrivez-vous comme donneur. Le comité valide votre inscription et vous contacte si votre groupe est recherché.',
    ],
    'become_donor_title': ['كن متبرعاً بالدم', 'Devenez donneur de sang'],
    'become_donor_desc': [
      'سجّل اسمك وفصيلة دمك ومدينتك ورقم هاتفك، وستراجع لجنة التبرع تسجيلك.',
      'Indiquez nom, groupe sanguin, ville et téléphone ; le comité validera votre inscription.',
    ],
    'donor_status_pending': ['قيد المراجعة', 'En attente'],
    'donor_status_approved': ['مقبول', 'Accepté'],
    'donor_status_rejected': ['مرفوض', 'Refusé'],
    'donor_pending_note': [
      'تسجيلك قيد مراجعة لجنة التبرع.',
      'Votre inscription est en cours de vérification par le comité.',
    ],
    'donor_approved_note': [
      'تم قبولك كمتبرع. قد تتواصل معك اللجنة عند الحاجة إلى فصيلتك.',
      'Vous êtes accepté. Le comité peut vous contacter si besoin.',
    ],
    'donor_rejected_note': [
      'لم يُقبل تسجيلك. يمكنك تعديل بياناتك لإعادة إرسالها أو التواصل مع الجمعية.',
      'Inscription refusée. Modifiez vos données pour la renvoyer ou contactez l’association.',
    ],
    'donor_review_info': [
      'بعد الحفظ يُرسل تسجيلك إلى لجنة التبرع للمراجعة (وكذلك عند كل تعديل).',
      'Après enregistrement, votre inscription est envoyée au comité (et à chaque modification).',
    ],
    'approve': ['قبول', 'Accepter'],
    'reject': ['رفض', 'Refuser'],
    'donor_approved_msg': ['تم قبول المتبرع', 'Donneur accepté'],
    'donor_rejected_msg': ['تم رفض التسجيل', 'Inscription refusée'],
    'donors_db': ['قاعدة المتبرعين', 'Base des donneurs'],
    'all_cities': ['كل المدن', 'Toutes les villes'],
    'pending_reviews': ['بانتظار المراجعة', 'à vérifier'],
    'approved_donors': ['متبرع مقبول', 'acceptés'],
    'my_blood_requests': ['طلبات الدم', 'Demandes de sang'],
    'new_blood_request': ['طلب دم جديد', 'Nouvelle demande'],
    'no_blood_requests': [
      'لا توجد طلبات دم. يمكنك تقديم طلب إذا احتجت دماً.',
      'Aucune demande. Vous pouvez en créer une si besoin.',
    ],
    'role_donor': ['متبرع بالدم', 'Donneur de sang'],
    'role_donor_desc': ['سجّل كمتبرع بالدم', 'Inscrivez-vous comme donneur'],
    // Committee: account reviews
    'patients': ['المرضى', 'Patients'],
    'doctors': ['الأطباء', 'Médecins'],
    'review_pending': ['قيد المراجعة', 'En attente'],
    'review_approved': ['مقبول', 'Accepté'],
    'review_rejected': ['مرفوض', 'Refusé'],
    'account_pending_title': [
      'حسابك قيد مراجعة لجنة التبرع',
      'Votre compte est en cours de vérification',
    ],
    'account_pending_patient': [
      'تتحقق اللجنة من بياناتك وبطاقة التعريف. يمكنك تصفّح التطبيق، وستصلك رسالة عند قبول حسابك.',
      'Le comité vérifie vos informations. Vous serez notifié dès l’acceptation.',
    ],
    'account_pending_doctor': [
      'تتحقق اللجنة من بطاقتك المهنية ورقم تسجيلك. لا يمكنك قبول الحالات قبل قبول حسابك.',
      'Le comité vérifie votre carte professionnelle. Vous pourrez accepter des cas après validation.',
    ],
    'account_rejected_title': ['لم يُقبل حسابك', 'Compte refusé'],
    'account_rejected_body': [
      'تواصل مع الجمعية لمعرفة السبب وتصحيح بياناتك.',
      'Contactez l’association pour en connaître la raison.',
    ],
    'doctor_not_approved': [
      'يمكنك قبول الحالات بعد أن توافق لجنة التبرع على حسابك.',
      'Vous pourrez accepter des cas après validation de votre compte.',
    ],
    'account_approved_msg': ['تم قبول الحساب', 'Compte accepté'],
    'account_rejected_msg': ['تم رفض الحساب', 'Compte refusé'],
    'phone_not_verified': ['الهاتف غير مؤكَّد', 'Téléphone non vérifié'],
    'details': ['التفاصيل', 'Détails'],
    'pending_registrations': [
      'تسجيل بانتظار المراجعة',
      'inscriptions à vérifier',
    ],
    'new_blood_requests': ['طلب دم جديد', 'demandes de sang'],
    'search_people_hint': [
      'ابحث بالاسم أو الرمز أو الهاتف',
      'Nom, code ou téléphone',
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
    'role_patient': ['مريض', 'Patient'],
    'role_patient_desc': ['سجِّل كمستفيد', 'Inscrivez-vous comme bénéficiaire'],
    'role_doctor': ['طبيب', 'Médecin'],
    'role_doctor_desc': [
      'سجِّل كطبيب متطوع',
      'Inscrivez-vous comme médecin bénévole',
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
    'attach_files': [
      'أرفق الفحوصات والتحاليل والوصفات الطبية',
      'Joignez examens, analyses et ordonnances',
    ],
    'attach_hint': [
      'صور واضحة تساعد الطبيب على القراءة الدقيقة',
      'Des photos nettes aident le médecin',
    ],
    'camera': ['الكاميرا', 'Caméra'],
    'gallery': ['المعرض', 'Galerie'],
    'pdf_file': ['ملف / PDF', 'Fichier / PDF'],
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
      'الاستشارات المقدمة عبر تطبيق شِفاءٌ لِلنّاس إرشادية وتطوعية، ولا تغني عن الكشف الطبي الحضوري أو العلاج في المستشفى.\n\n'
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
