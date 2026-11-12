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
      'مثلاً: «طبيب قلب في نواذيبو» أو «أطفال»',
      'Ex : « cardiologue à Nouadhibou » ou « pédiatrie »',
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
      'أوافق على أن يتواصل معي فريق المتابعة والإدارة عند الحاجة إلى فصيلتي',
      'J’accepte que l’équipe de suivi me contacte si mon groupe est recherché',
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
      'بيانات المتبرعين سرية: لا يطّلع عليها إلا فريق المتابعة والإدارة، ولا تُعرض على المستخدمين الآخرين.',
      'Les données des donneurs sont confidentielles : seule l’équipe de suivi y a accès.',
    ],
    'your_request': ['طلبك', 'Votre demande'],
    // Blood donation: committee, privacy, personal info
    'role_committee': [
      'فريق المتابعة والإدارة',
      'Équipe de suivi et de gestion',
    ],
    'committee_login': [
      'دخول فريق المتابعة والإدارة',
      'Accès équipe de suivi et de gestion',
    ],
    'committee_title': [
      'فريق المتابعة والإدارة',
      'Équipe de suivi et de gestion',
    ],
    'committee_only': [
      'هذه المعلومات لا تظهر إلا لفريق المتابعة والإدارة',
      'Informations visibles par l’équipe de suivi uniquement',
    ],
    'committee_will_contact': [
      'سيتواصل معك فريق المتابعة والإدارة لترتيب التبرع. بياناتك لا تُعرض على أحد.',
      'L’équipe de suivi vous contactera pour organiser le don. Vos données restent confidentielles.',
    ],
    'committee_reviews_request': [
      'يراجع فريق المتابعة والإدارة طلبك ويربطه بمتبرعين مناسبين، ثم يتصل بك.',
      'L’équipe de suivi étudie votre demande, la relie à des donneurs compatibles puis vous appelle.',
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
      'سجّل كمتبرع بالدم. يراجع فريق المتابعة والإدارة تسجيلك، ثم يتواصل معك عند الحاجة إلى فصيلتك.',
      'Inscrivez-vous comme donneur. L’équipe de suivi valide votre inscription et vous contacte si votre groupe est recherché.',
    ],
    'become_donor_title': ['كن متبرعاً بالدم', 'Devenez donneur de sang'],
    'become_donor_desc': [
      'سجّل اسمك وفصيلة دمك ومدينتك ورقم هاتفك، وسيراجع فريق المتابعة والإدارة تسجيلك.',
      'Indiquez nom, groupe sanguin, ville et téléphone ; l’équipe de suivi validera votre inscription.',
    ],
    'donor_status_pending': ['قيد المراجعة', 'En attente'],
    'donor_status_approved': ['مقبول', 'Accepté'],
    'donor_status_rejected': ['مرفوض', 'Refusé'],
    'donor_pending_note': [
      'تسجيلك قيد مراجعة فريق المتابعة والإدارة.',
      'Votre inscription est en cours de vérification par l’équipe de suivi.',
    ],
    'donor_approved_note': [
      'تم قبولك كمتبرع. قد يتواصل معك الفريق عند الحاجة إلى فصيلتك.',
      'Vous êtes accepté. L’équipe de suivi peut vous contacter si besoin.',
    ],
    'donor_rejected_note': [
      'لم يُقبل تسجيلك. يمكنك تعديل بياناتك لإعادة إرسالها أو التواصل مع الجمعية.',
      'Inscription refusée. Modifiez vos données pour la renvoyer ou contactez l’association.',
    ],
    'donor_review_info': [
      'بعد الحفظ يُرسل تسجيلك إلى فريق المتابعة والإدارة للمراجعة (وكذلك عند كل تعديل).',
      'Après enregistrement, votre inscription est envoyée à l’équipe de suivi (et à chaque modification).',
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
      'حسابك قيد مراجعة فريق المتابعة والإدارة',
      'Votre compte est en cours de vérification',
    ],
    'account_pending_patient': [
      'يتحقق الفريق من بياناتك وبطاقة التعريف. يمكنك تصفّح التطبيق، وستصلك رسالة عند قبول حسابك.',
      'L’équipe de suivi vérifie vos informations. Vous serez notifié dès l’acceptation.',
    ],
    'account_pending_doctor': [
      'يتحقق الفريق من بطاقتك المهنية ورقم تسجيلك. لا يمكنك قبول الحالات قبل قبول حسابك.',
      'L’équipe de suivi vérifie votre carte professionnelle. Vous pourrez accepter des cas après validation.',
    ],
    'account_rejected_title': ['لم يُقبل حسابك', 'Compte refusé'],
    'account_rejected_body': [
      'تواصل مع الجمعية لمعرفة السبب وتصحيح بياناتك.',
      'Contactez l’association pour en connaître la raison.',
    ],
    'doctor_not_approved': [
      'يمكنك قبول الحالات بعد أن يوافق فريق المتابعة والإدارة على حسابك.',
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
    'request_blood_desc': [
      'لك أو لأحد أقاربك، ويتابعه فريق المتابعة والإدارة',
      'Pour vous ou un proche, suivie par l’équipe',
    ],
    'blood_requests_open': [
      'لديك {n} طلب دم قيد المتابعة',
      '{n} demande(s) en cours',
    ],
    'medical_document': [
      'وثيقة طبية (اختياري)',
      'Document médical (facultatif)',
    ],
    'medical_document_hint': [
      'تقرير طبي أو طلب المستشفى أو تحليل الفصيلة — يطّلع عليه فريق المتابعة والإدارة فقط',
      'Rapport, demande de l’hôpital ou groupage — visible par l’équipe uniquement',
    ],
    'add_document': ['إرفاق وثيقة', 'Joindre un document'],
    'documents': ['الوثائق المرفقة', 'Documents joints'],
    'location_hospital': ['الموقع (المستشفى)', 'Lieu (hôpital)'],
    'contact_number': ['رقم التواصل', 'Numéro de contact'],
    'quantity': ['الكمية', 'Quantité'],
    'add_external_donor': [
      'إضافة متبرع من خارج المنصة',
      'Ajouter un donneur externe',
    ],
    'external_donor_hint': [
      'متبرع غير مسجّل في المنصة (من معارفه أو من بنك الدم...) يتحقق منه الفريق مباشرة.',
      'Donneur non inscrit (entourage, banque de sang...), vérifié directement par l’équipe.',
    ],
    'add_and_link': ['إضافة وربط بالطلب', 'Ajouter et lier'],
    'add_donor': ['إضافة متبرع', 'Ajouter un donneur'],
    'external_donor_added': ['تمت إضافة المتبرع', 'Donneur ajouté'],
    'team_notes': ['ملاحظات المتابعة', 'Notes de suivi'],
    'team_notes_hint': [
      'مثال: اتصلت بالمتبرع، موعده غداً 9 صباحاً',
      'Ex : donneur appelé, rendez-vous demain 9 h',
    ],
    'add_note': ['إضافة', 'Ajouter'],
    'no_notes': ['لا توجد ملاحظات بعد', 'Aucune note'],
    'not_compatible_type': [
      'تنبيه: هذه الفصيلة غير متوافقة مع الفصيلة المطلوبة',
      'Attention : groupe non compatible avec la demande',
    ],
    'about_association': ['عن الجمعية', 'L’association'],
    'support_association': ['ادعم الجمعية', 'Soutenir l’association'],
    'support_association_desc': [
      'للتبرع لجمعية عون وسند الخيرية تواصل معنا على الرقم:',
      'Pour faire un don à l’association, contactez-nous au :',
    ],
    // Patient map (medical aid committee)
    'aid_title': ['طلب مساعدة طبية', 'Demande d’aide médicale'],
    'aid_home_desc': [
      'شارك موقعك لتصلك لجنة العون الطبي',
      'Partagez votre position avec le comité d’aide médicale',
    ],
    'aid_my_requests': ['طلبات المساعدة', 'Mes demandes d’aide'],
    'aid_new': ['طلب مساعدة جديد', 'Nouvelle demande'],
    'aid_intro': [
      'سجّل طلبك وحدّد موقعك على الخريطة، وستتحقق لجنة العون الطبي من الحالة وتتواصل معك.',
      'Indiquez votre position : le comité d’aide médicale vérifiera la situation et vous contactera.',
    ],
    'aid_none': ['لا توجد طلبات مساعدة بعد', 'Aucune demande pour le moment'],
    'aid_condition': ['وصف الحالة', 'Description de la situation'],
    'aid_condition_hint': [
      'مثال: مسنة مقعدة تحتاج زيارة طبيب وأدوية الضغط',
      'Ex : personne âgée alitée, besoin d’une visite et de médicaments',
    ],
    'aid_urgency': ['درجة الاستعجال', 'Degré d’urgence'],
    'aid_urg_urgent': ['عاجل', 'Urgent'],
    'aid_urg_medium': ['متوسط', 'Moyen'],
    'aid_urg_normal': ['عادي', 'Normal'],
    'aid_address_note': [
      'ملاحظة عن العنوان (الحي، أقرب معلم...)',
      'Indication d’adresse (quartier, repère...)',
    ],
    'aid_location': ['الموقع على الخريطة', 'Position sur la carte'],
    'aid_locate_me': ['تحديد موقعي', 'Me localiser'],
    'aid_locating': ['جارٍ تحديد الموقع...', 'Localisation...'],
    'aid_move_map_hint': [
      'حرّك الخريطة ليقع الدبوس على المنزل بدقة',
      'Déplacez la carte pour placer l’épingle sur le domicile',
    ],
    'aid_location_required': [
      'حدّد الموقع على الخريطة أولاً',
      'Indiquez d’abord la position sur la carte',
    ],
    'aid_location_off': [
      'خدمة الموقع متوقفة في الجهاز. فعّلها أو حرّك الخريطة يدوياً.',
      'Localisation désactivée. Activez-la ou déplacez la carte.',
    ],
    'aid_location_denied': [
      'لم يُسمح بالوصول إلى الموقع. يمكنك تحريك الخريطة يدوياً.',
      'Accès refusé. Vous pouvez déplacer la carte manuellement.',
    ],
    'aid_location_set': ['تم تحديد الموقع', 'Position définie'],
    'aid_consent': [
      'أوافق على مشاركة موقعي وبياناتي مع لجنة العون الطبي فقط، لغرض تقديم المساعدة',
      'J’accepte de partager ma position et mes données uniquement avec le comité d’aide médicale',
    ],
    'aid_consent_required': [
      'الموافقة مطلوبة لإرسال الطلب',
      'Le consentement est requis',
    ],
    'aid_submit': ['إرسال الطلب', 'Envoyer la demande'],
    'aid_sent': [
      'تم إرسال طلبك إلى لجنة العون الطبي',
      'Demande envoyée au comité d’aide médicale',
    ],
    'aid_st_newRequest': ['جديد', 'Nouveau'],
    'aid_st_verifying': ['قيد التحقق', 'En vérification'],
    'aid_st_verified': ['تم التحقق', 'Vérifié'],
    'aid_st_helped': ['تمت المساعدة', 'Aidé'],
    'aid_st_closed': ['مغلق', 'Clôturé'],
    'aid_map': ['خريطة المرضى', 'Carte des patients'],
    'aid_committee_only': [
      'هذه الخريطة لأعضاء لجنة العون الطبي فقط',
      'Carte réservée au comité d’aide médicale',
    ],
    'aid_open_only': ['الحالات المفتوحة', 'Cas ouverts'],
    'aid_n_requests': ['{n} طلب', '{n} demande(s)'],
    'aid_list': ['القائمة', 'Liste'],
    'aid_directions': ['الاتجاهات', 'Itinéraire'],
    'aid_verified_on': ['تحقق منه في {date}', 'Vérifié le {date}'],
    'aid_change_status': ['تغيير الحالة', 'Changer le statut'],
    'aid_status_updated': ['تم تحديث الحالة', 'Statut mis à jour'],
    'aid_delete': ['حذف الحالة', 'Supprimer le cas'],
    'aid_delete_confirm': [
      'حذف هذه الحالة نهائياً؟ لا يمكن التراجع.',
      'Supprimer définitivement ce cas ?',
    ],
    'aid_deleted': ['تم حذف الحالة', 'Cas supprimé'],
    'aid_supervisor_only': [
      'إغلاق الحالات وحذفها للمشرف فقط',
      'Clôture et suppression réservées au superviseur',
    ],
    'aid_error': ['تعذّر تنفيذ العملية: {e}', 'Échec de l’opération : {e}'],
    'aid_members': ['أعضاء اللجنة', 'Membres du comité'],
    'aid_role_member': ['عضو', 'Membre'],
    'aid_role_supervisor': ['مشرف', 'Superviseur'],
    'aid_add_member': ['إضافة عضو', 'Ajouter un membre'],
    'aid_member_user_id': [
      'رمز حساب العضو (User ID)',
      'Identifiant du compte (User ID)',
    ],
    'aid_my_user_id': [
      'رمز حسابك (أرسله للمشرف ليضيفك إلى اللجنة):',
      'Votre identifiant (à envoyer au superviseur) :',
    ],
    'aid_remove': ['إزالة', 'Retirer'],
    'aid_demo_mode': [
      'وضع تجريبي: بيانات وهمية في نواكشوط، لا يُرسل أي شيء إلى الخادم.',
      'Mode démo : données fictives à Nouakchott, rien n’est envoyé.',
    ],
    'aid_sign_in_title': [
      'سجّل الدخول لإرسال طلب أو متابعته',
      'Connectez-vous pour envoyer ou suivre une demande',
    ],
    'email': ['البريد الإلكتروني', 'E-mail'],
    'aid_sign_up': ['إنشاء حساب', 'Créer un compte'],
    'aid_have_account': ['لديّ حساب', 'J’ai un compte'],
    'aid_check_email': [
      'تم إنشاء الحساب. إذا طُلب تأكيد البريد، افتح الرسالة ثم سجّل الدخول.',
      'Compte créé. Confirmez votre e-mail si demandé, puis connectez-vous.',
    ],
    'aid_sign_out': ['تسجيل الخروج من الخريطة', 'Se déconnecter'],
    'aid_osm_credit': [
      '© مساهمو OpenStreetMap',
      '© contributeurs OpenStreetMap',
    ],
    // ---------------- Medical facilities ----------------
    'role_facility': ['جهة طبية', 'Structure médicale'],
    'role_facility_desc': [
      'مستشفى، عيادة، مختبر، صيدلية أو مركز أشعة',
      'Hôpital, clinique, laboratoire, pharmacie ou radiologie',
    ],
    'facility_intro': [
      'انضمّوا إلى شبكة الجهات الطبية المتعاونة مع جمعية عون وسند الخيرية: قدّموا خدمات مجانية أو مخفّضة، واستقبلوا المرضى المحالين من الجمعية، وتابعوا حالاتهم من حساب خاص بجهتكم.',
      'Rejoignez le réseau des structures médicales partenaires de l’association Aoun wa Sanad : offrez des services gratuits ou à prix réduit, recevez les patients orientés par l’association et suivez leurs dossiers depuis un compte dédié.',
    ],
    'facility_register': ['تسجيل جهة طبية جديدة', 'Inscrire une structure'],
    'facility_login': ['دخول حساب الجهة', 'Accéder au compte'],
    'facility_demo_hint': [
      'حساب تجريبي: الهاتف 45 25 10 10 — رقم الترخيص MS-NKC-2019-114',
      'Compte démo : tél. 45 25 10 10 — licence MS-NKC-2019-114',
    ],
    'demo_login': ['دخول بالحساب التجريبي', 'Connexion au compte démo'],
    'facility_type': ['نوع الجهة', 'Type de structure'],
    'ft_hospital': ['مستشفى', 'Hôpital'],
    'ft_clinic': ['عيادة', 'Clinique'],
    'ft_lab': ['مختبر', 'Laboratoire'],
    'ft_pharmacy': ['صيدلية', 'Pharmacie'],
    'ft_radiology': ['مركز أشعة', 'Centre de radiologie'],
    'facility_name': ['اسم الجهة', 'Nom de la structure'],
    'facility_manager': ['اسم المسؤول', 'Nom du responsable'],
    'facility_license': ['رقم الترخيص', 'Numéro d’autorisation'],
    'facility_license_doc': ['صورة الترخيص', 'Copie de l’autorisation'],
    'address': ['العنوان', 'Adresse'],
    'facility_section_info': ['بيانات الجهة', 'Informations'],
    'facility_section_services': [
      'التخصصات والخدمات',
      'Spécialités et services',
    ],
    'facility_section_coop': [
      'نوع التعاون مع الجمعية',
      'Coopération avec l’association',
    ],
    'facility_specialties': ['التخصصات المتوفرة', 'Spécialités disponibles'],
    'facility_services': ['الخدمات المقدّمة', 'Services proposés'],
    'facility_services_hint': [
      'اكتب الخدمة ثم اضغط إضافة (مثال: تحليل الدم الشامل)',
      'Saisissez un service puis Ajouter (ex. : NFS)',
    ],
    'add': ['إضافة', 'Ajouter'],
    'coop_free': ['خدمات مجانية', 'Services gratuits'],
    'coop_free_desc': [
      'تقديم بعض الخدمات مجاناً لمرضى الجمعية',
      'Certains services offerts aux patients de l’association',
    ],
    'coop_discounted': ['خدمات مخفّضة', 'Services à prix réduit'],
    'coop_discounted_desc': [
      'تخفيض على الأسعار لمرضى الجمعية',
      'Réduction sur les tarifs pour les patients de l’association',
    ],
    'coop_referrals': [
      'استقبال المرضى المحالين',
      'Accueil des patients orientés',
    ],
    'coop_referrals_desc': [
      'استقبال المرضى الذين تحيلهم الجمعية ومتابعة حالاتهم',
      'Recevoir les patients orientés par l’association et suivre leurs cas',
    ],
    'discount_percent': ['نسبة التخفيض %', 'Réduction %'],
    'discount_value': ['تخفيض {n}%', 'Réduction {n} %'],
    'monthly_capacity': [
      'عدد المرضى المحالين شهرياً',
      'Patients orientés par mois',
    ],
    'capacity_value': ['{n} حالة شهرياً', '{n} cas / mois'],
    'facility_notes': ['ملاحظات إضافية', 'Remarques'],
    'facility_consent': [
      'أُقرّ بصحة البيانات، وأوافق على مراجعتها من فريق المتابعة والإدارة والتواصل معنا بشأن المرضى المحالين مع الحفاظ على سرّيتهم.',
      'Je certifie l’exactitude des informations et accepte leur vérification par l’équipe de suivi et le contact concernant les patients orientés, dans le respect de leur confidentialité.',
    ],
    'facility_need_coop': [
      'اختر نوع تعاون واحداً على الأقل',
      'Choisissez au moins un type de coopération',
    ],
    'facility_submit': ['إرسال طلب التسجيل', 'Envoyer la demande'],
    'facility_submitted': [
      'تم إرسال طلب تسجيل الجهة، وسيراجعه فريق المتابعة والإدارة.',
      'Demande envoyée. L’équipe de suivi va l’examiner.',
    ],
    'facility_pending_title': [
      'طلبكم قيد المراجعة',
      'Demande en cours d’examen',
    ],
    'facility_pending_body': [
      'يراجع فريق المتابعة والإدارة بيانات الجهة والترخيص، وسيتواصل معكم قريباً. بعد الاعتماد تظهر هنا الإحالات الواردة من الجمعية.',
      'L’équipe vérifie vos informations et votre autorisation, puis vous contactera. Après validation, les orientations de l’association apparaîtront ici.',
    ],
    'facility_rejected_title': ['لم يُعتمد طلب التسجيل', 'Demande non validée'],
    'facility_rejected_body': [
      'يمكنكم التواصل مع الجمعية لاستكمال البيانات أو تصحيحها.',
      'Contactez l’association pour compléter ou corriger vos informations.',
    ],
    'facility_login_failed': [
      'لم نجد جهة بهذا الهاتف ورقم الترخيص',
      'Aucune structure avec ce téléphone et cette autorisation',
    ],
    'facility_approved_badge': ['جهة معتمدة', 'Structure agréée'],
    'facility_tab_referrals': ['الإحالات', 'Orientations'],
    'facility_tab_profile': ['ملف الجهة', 'Profil'],
    'facilities': ['الجهات الطبية', 'Structures médicales'],
    'no_facilities': ['لا توجد جهات', 'Aucune structure'],
    'facility_approved_msg': [
      'تم اعتماد الجهة وتفعيل حسابها',
      'Structure validée, compte activé',
    ],
    'facility_rejected_msg': ['تم رفض طلب الجهة', 'Demande refusée'],
    'refer_patient': ['إحالة مريض', 'Orienter un patient'],
    'referral_patient_name': ['اسم المريض', 'Nom du patient'],
    'referral_patient_ref': [
      'رقم ملف المريض بالجمعية',
      'N° de dossier à l’association',
    ],
    'referral_service': ['الخدمة المطلوبة', 'Service demandé'],
    'referral_notes': ['ملاحظات للجهة', 'Remarques pour la structure'],
    'referral_urgent': ['حالة مستعجلة', 'Cas urgent'],
    'referral_send': ['إرسال الإحالة', 'Envoyer l’orientation'],
    'referral_sent_msg': ['تم إرسال الإحالة إلى الجهة', 'Orientation envoyée'],
    'referrals_new': ['جديدة', 'Nouvelles'],
    'referrals_open': ['قيد المتابعة', 'En suivi'],
    'referrals_closed': ['منتهية', 'Clôturées'],
    'no_referrals': ['لا توجد إحالات', 'Aucune orientation'],
    'rs_sent': ['إحالة جديدة', 'Nouvelle'],
    'rs_accepted': ['مقبولة', 'Acceptée'],
    'rs_inProgress': ['المريض قيد المتابعة', 'Patient pris en charge'],
    'rs_completed': ['تمت الخدمة', 'Service rendu'],
    'rs_declined': ['معتذَر عنها', 'Déclinée'],
    'ra_accepted': ['قبول الإحالة', 'Accepter'],
    'ra_inProgress': ['استقبلنا المريض', 'Patient reçu'],
    'ra_completed': ['تمت الخدمة', 'Service rendu'],
    'ra_declined': ['اعتذار', 'Décliner'],
    'referral_update_note': [
      'ملاحظة للجمعية (موعد، نتيجة...)',
      'Note pour l’association (RDV, résultat…)',
    ],
    'referral_updated_msg': [
      'تم تحديث حالة الإحالة',
      'Orientation mise à jour',
    ],
    'referral_details': ['تفاصيل الإحالة', 'Détails de l’orientation'],
    'referral_from_association': [
      'محالة من الجمعية',
      'Orientée par l’association',
    ],
    'facility_note': ['ملاحظة الجهة', 'Note de la structure'],
    'last_update': ['آخر تحديث: {t}', 'Mise à jour : {t}'],
    'referrals_count': ['{n} إحالة', '{n} orientation(s)'],
    'referrals_of_facility': ['إحالات الجهة', 'Orientations de la structure'],
    'fstep_basic': ['البيانات الأساسية', 'Informations de base'],
    'fstep_services': [
      'النوع والتخصصات والخدمات',
      'Type, spécialités et services',
    ],
    'fstep_contact': [
      'المسؤول والتواصل والعنوان',
      'Responsable, contact et adresse',
    ],
    'fstep_documents': ['الترخيص والوثائق', 'Autorisation et documents'],
    'fstep_send': ['مراجعة وإرسال', 'Vérifier et envoyer'],
    'legal_documents': ['الوثائق القانونية الأخرى', 'Autres documents légaux'],
    'legal_documents_hint': [
      'مثل: السجل التجاري، بطاقة تعريف المسؤول، شهادة مزاولة المهنة',
      'Ex. : registre de commerce, pièce d’identité du responsable, attestation d’exercice',
    ],
    'license_required': [
      'يرجى رفع صورة الترخيص الرسمي',
      'Veuillez joindre l’autorisation officielle',
    ],
    'fs_pending': ['قيد المراجعة', 'En cours d’examen'],
    'fs_needsInfo': ['مطلوب استكمال الوثائق', 'Documents à compléter'],
    'fs_approved': ['معتمدة', 'Agréée'],
    'fs_rejected': ['مرفوضة', 'Refusée'],
    'fe_submitted': ['تم إرسال طلب التسجيل', 'Demande envoyée'],
    'fe_resubmitted': [
      'أُرسلت الوثائق المطلوبة',
      'Documents complétés envoyés',
    ],
    'fe_needsInfo': [
      'طلبت الإدارة استكمال الوثائق',
      'L’administration demande des compléments',
    ],
    'fe_approved': [
      'تم اعتماد الجهة وتفعيل حسابها',
      'Structure agréée, compte activé',
    ],
    'fe_rejected': ['تم رفض الطلب', 'Demande refusée'],
    'registration_history': ['مسار طلب التسجيل', 'Suivi de la demande'],
    'verification': [
      'التحقق من البيانات والوثائق',
      'Vérification des données et documents',
    ],
    'vc_data': [
      'بيانات الجهة صحيحة ومكتملة',
      'Informations exactes et complètes',
    ],
    'vc_license': [
      'الترخيص الرسمي صحيح وساري المفعول',
      'Autorisation officielle valide',
    ],
    'vc_documents': ['الوثائق القانونية مكتملة', 'Documents légaux complets'],
    'vc_contact': [
      'تم التواصل مع المسؤول والتأكد منه',
      'Responsable contacté et confirmé',
    ],
    'verify_first': [
      'أكمل بنود التحقق قبل الاعتماد',
      'Complétez la vérification avant de valider',
    ],
    'decision': ['القرار', 'Décision'],
    'request_completion': ['طلب استكمال', 'Demander des compléments'],
    'reject_reason': ['سبب الرفض', 'Motif du refus'],
    'missing_documents': [
      'الوثائق أو البيانات المطلوب استكمالها',
      'Documents ou informations à compléter',
    ],
    'reason_required': ['يرجى كتابة السبب', 'Veuillez indiquer le motif'],
    'completion_requested_msg': [
      'تم إرسال طلب الاستكمال إلى الجهة',
      'Demande de compléments envoyée',
    ],
    'review_request': ['مراجعة الطلب', 'Examiner la demande'],
    'team_message': ['رسالة الإدارة', 'Message de l’administration'],
    'complete_and_resend': [
      'إرسال الوثائق المطلوبة',
      'Envoyer les compléments',
    ],
    'resend_note': [
      'ملاحظة للإدارة (اختياري)',
      'Note pour l’administration (facultatif)',
    ],
    'resent_msg': [
      'تم إرسال الوثائق، والطلب قيد المراجعة من جديد',
      'Compléments envoyés, demande réexaminée',
    ],
    'needs_info_body': [
      'طلبت إدارة الجمعية استكمال بعض الوثائق أو البيانات. ارفعوها ثم أعيدوا إرسال الطلب.',
      'L’association demande des documents ou informations supplémentaires. Ajoutez-les puis renvoyez la demande.',
    ],
    'approval_notice_title': [
      'مبروك! تم اعتماد جهتكم',
      'Félicitations ! Votre structure est agréée',
    ],
    'approval_notice_body': [
      'تم تفعيل حساب الجهة لدى جمعية عون وسند الخيرية، وستصلكم هنا إحالات المرضى من الجمعية.',
      'Le compte de votre structure est activé auprès de l’association Aoun wa Sanad. Les orientations de patients arriveront ici.',
    ],
    'got_it': ['حسناً', 'Compris'],
    // ---------------- Psychological consultations ----------------
    'sp_psych': ['الطب النفسي', 'Psychiatrie'],
    'psych_title': ['الاستشارات النفسية', 'Soutien psychologique'],
    'psych_card_desc': [
      'تحدّث بسرية مع طبيب نفسي متطوع واحجز موعدك',
      'Parlez en toute confidentialité à un psychiatre bénévole',
    ],
    'psych_intro': [
      'صحتك النفسية لا تقل أهمية عن صحتك الجسدية. احجز جلسة مجانية مع طبيب نفسي متطوع، كتابياً أو بمكالمة صوتية أو مرئية، وبسرية تامة.',
      'Votre santé mentale compte autant que votre santé physique. Réservez une séance gratuite avec un psychiatre bénévole, par écrit, appel audio ou vidéo, en toute confidentialité.',
    ],
    'psych_privacy_points': [
      '• لا يطّلع على جلستك إلا الطبيب الذي تختاره.\n• يمكنك استخدام اسم مستعار بدل اسمك الحقيقي.\n• لا يرى فريق الجمعية ولا أي طبيب آخر محتوى الجلسة.\n• ملاحظات الطبيب الخاصة سرية لا يطّلع عليها أحد.',
      '• Seul le médecin choisi voit votre séance.\n• Vous pouvez utiliser un pseudonyme.\n• Ni l’équipe de l’association ni un autre médecin ne voient son contenu.\n• Les notes personnelles du médecin restent confidentielles.',
    ],
    'psych_privacy_title': ['خصوصيتك محفوظة', 'Votre vie privée est protégée'],
    'psych_book': ['طلب استشارة نفسية', 'Demander une consultation'],
    'psych_my_sessions': ['جلساتي', 'Mes séances'],
    'psych_no_sessions': ['لا توجد جلسات بعد', 'Aucune séance pour le moment'],
    'psych_crisis_title': ['هل أنت في خطر الآن؟', 'Êtes-vous en danger ?'],
    'psych_crisis_body': [
      'إذا كانت لديك أفكار لإيذاء نفسك أو كنت في خطر الآن، اتصل فوراً بالإسعاف أو توجّه إلى أقرب قسم طوارئ، وأخبر شخصاً تثق به. الاستشارة عن بُعد لا تغني عن المساعدة العاجلة.',
      'Si vous pensez à vous faire du mal ou êtes en danger, appelez immédiatement les secours ou rendez-vous aux urgences les plus proches, et prévenez une personne de confiance. La téléconsultation ne remplace pas l’aide urgente.',
    ],
    'pstep_need': ['ما الذي يقلقك؟', 'Votre besoin'],
    'pstep_doctor': ['الطبيب', 'Médecin'],
    'pstep_time': ['الموعد', 'Rendez-vous'],
    'pstep_privacy': ['الخصوصية', 'Confidentialité'],
    'psych_topics': ['المواضيع (اختر ما يناسبك)', 'Sujets (choisissez)'],
    'pt_anxiety': ['القلق والتوتر', 'Anxiété'],
    'pt_depression': ['الحزن والاكتئاب', 'Tristesse, dépression'],
    'pt_stress': ['الضغوط اليومية', 'Stress'],
    'pt_sleep': ['اضطرابات النوم', 'Troubles du sommeil'],
    'pt_family': ['مشاكل أسرية', 'Difficultés familiales'],
    'pt_trauma': ['صدمة أو فقدان', 'Traumatisme, deuil'],
    'pt_addiction': ['الإدمان', 'Addiction'],
    'pt_other': ['أخرى', 'Autre'],
    'psych_describe': [
      'صف ما تمر به باختصار (اختياري)',
      'Décrivez brièvement (facultatif)',
    ],
    'psych_risk_question': [
      'هل تراودك أفكار لإيذاء نفسك أو إنهاء حياتك؟',
      'Avez-vous des pensées de vous faire du mal ?',
    ],
    'psych_risk_yes': ['نعم', 'Oui'],
    'psych_risk_no': ['لا', 'Non'],
    'psych_risk_note': [
      'شكراً لصراحتك. سيُبلَّغ الطبيب بأولوية طلبك، لكن إن كنت في خطر الآن فلا تنتظر الموعد:',
      'Merci de votre franchise. Le médecin sera prévenu en priorité, mais si vous êtes en danger maintenant, n’attendez pas :',
    ],
    'psych_choose_doctor': [
      'اختر طبيباً نفسياً متطوعاً',
      'Choisissez un psychiatre bénévole',
    ],
    'psych_session_mode': ['طريقة الجلسة', 'Type de séance'],
    'sm_chat': ['محادثة كتابية', 'Messagerie'],
    'sm_voice': ['مكالمة صوتية', 'Appel audio'],
    'sm_video': ['مكالمة مرئية', 'Appel vidéo'],
    'psych_choose_slot': [
      'اختر يوم ووقت الجلسة (45 دقيقة)',
      'Choisissez le jour et l’heure (45 min)',
    ],
    'psych_no_slots': [
      'لا مواعيد متاحة لهذا الطبيب حالياً',
      'Aucun créneau disponible',
    ],
    'psych_alias': [
      'الاسم الذي يظهر للطبيب (اسم مستعار)',
      'Nom affiché au médecin (pseudonyme)',
    ],
    'psych_share_name': [
      'إظهار اسمي الحقيقي للطبيب',
      'Montrer mon vrai nom au médecin',
    ],
    'psych_consent': [
      'أوافق على شروط الاستشارة النفسية عن بُعد، وأعلم أنها لا تغني عن الطوارئ.',
      'J’accepte les conditions de la téléconsultation psychologique et sais qu’elle ne remplace pas les urgences.',
    ],
    'psych_confirm_booking': ['تأكيد الحجز', 'Confirmer la réservation'],
    'psych_booked': [
      'تم إرسال طلب الموعد، وسيؤكده الطبيب قريباً.',
      'Demande envoyée, le médecin va confirmer le rendez-vous.',
    ],
    'ps_requested': ['بانتظار تأكيد الطبيب', 'En attente de confirmation'],
    'ps_confirmed': ['موعد مؤكد', 'Rendez-vous confirmé'],
    'ps_completed': ['تمت الجلسة', 'Séance terminée'],
    'ps_declined': ['اعتذر الطبيب', 'Refusé par le médecin'],
    'ps_cancelled': ['ملغاة', 'Annulée'],
    'psych_session': ['جلسة نفسية', 'Séance psychologique'],
    'psych_appointment': ['الموعد', 'Rendez-vous'],
    'psych_cancel': ['إلغاء الموعد', 'Annuler le rendez-vous'],
    'psych_cancel_confirm': [
      'هل تريد إلغاء هذا الموعد؟',
      'Annuler ce rendez-vous ?',
    ],
    'psych_cancelled_msg': ['تم إلغاء الموعد', 'Rendez-vous annulé'],
    'psych_declined_hint': [
      'يمكنك حجز موعد آخر مع الطبيب نفسه أو مع طبيب آخر.',
      'Vous pouvez réserver un autre créneau ou un autre médecin.',
    ],
    'psych_book_again': ['حجز موعد جديد', 'Nouveau rendez-vous'],
    'psych_recommendations': ['توصيات الطبيب', 'Conseils du médecin'],
    'psych_messages': ['المحادثة الخاصة', 'Messagerie privée'],
    'psych_message_hint': ['اكتب رسالة...', 'Écrire un message…'],
    'psych_messages_locked': [
      'تُفتح المحادثة بعد تأكيد الموعد.',
      'La messagerie s’ouvre après confirmation du rendez-vous.',
    ],
    'psych_call_note': [
      'سيتصل بك الطبيب في موعد الجلسة عبر التطبيق.',
      'Le médecin vous appellera via l’application à l’heure du rendez-vous.',
    ],
    'psych_follow_up': ['جلسة متابعة', 'Séance de suivi'],
    'psych_pledge_title': [
      'تعهّد السرية المهنية',
      'Engagement de confidentialité',
    ],
    'psych_pledge': [
      'أتعهد بالحفاظ على سرية الاستشارات النفسية، وعدم مشاركة أي معلومة أو تسجيل أو صورة تخص المستفيدين، واستخدام بياناتهم لغرض العلاج فقط، والتعامل مع حالات الخطر وفق الأصول المهنية.',
      'Je m’engage à respecter le secret des consultations, à ne partager aucune information, enregistrement ou image des patients, à n’utiliser leurs données que pour les soigner et à gérer les situations de risque selon les règles professionnelles.',
    ],
    'psych_pledge_required': [
      'يجب الموافقة على تعهّد السرية للأطباء النفسيين',
      'Les psychiatres doivent accepter l’engagement de confidentialité',
    ],
    'psych_pledge_accept': ['أوافق وأتعهد', 'J’accepte et je m’engage'],
    'psych_demo_login': ['دخول تجريبي: طبيب نفسي', 'Démo : psychiatre'],
    'psych_doctor_space': ['مساحة الطبيب النفسي', 'Espace psychiatre'],
    'psych_tab_requests': ['طلبات جديدة', 'Demandes'],
    'psych_tab_upcoming': ['المواعيد', 'Rendez-vous'],
    'psych_tab_followup': ['المتابعة', 'Suivi'],
    'psych_tab_profile': ['الملف', 'Profil'],
    'psych_confirm': ['تأكيد الموعد', 'Confirmer'],
    'psych_decline': ['اعتذار', 'Refuser'],
    'psych_confirmed_msg': [
      'تم تأكيد الموعد وإشعار المستفيد',
      'Rendez-vous confirmé',
    ],
    'psych_declined_msg': ['تم الاعتذار وإشعار المستفيد', 'Demande refusée'],
    'psych_risk_badge': ['أولوية: مؤشر خطر', 'Priorité : risque'],
    'psych_risk_doctor_hint': [
      'أشار المستفيد إلى أفكار لإيذاء النفس. يُنصح بالتواصل في أقرب وقت وتقييم الخطر وتوجيهه للطوارئ عند الحاجة.',
      'Le patient signale des idées d’auto-agression. Contactez-le rapidement, évaluez le risque et orientez-le vers les urgences si besoin.',
    ],
    'psych_private_notes': ['ملاحظاتي السرية', 'Mes notes confidentielles'],
    'psych_private_notes_hint': [
      'لا يراها المستفيد ولا فريق الجمعية',
      'Invisibles pour le patient et l’équipe',
    ],
    'psych_notes_saved': ['تم حفظ الملاحظات', 'Notes enregistrées'],
    'psych_complete': ['إنهاء الجلسة', 'Terminer la séance'],
    'psych_complete_hint': [
      'توصيات تظهر للمستفيد (اختياري)',
      'Conseils pour le patient (facultatif)',
    ],
    'psych_completed_msg': ['تم إنهاء الجلسة', 'Séance terminée'],
    'psych_schedule_follow_up': ['حجز جلسة متابعة', 'Planifier un suivi'],
    'psych_follow_up_booked': [
      'تم حجز جلسة المتابعة',
      'Séance de suivi planifiée',
    ],
    'psych_patient': ['المستفيد', 'Patient'],
    'psych_age_sex': ['{age} سنة • {sex}', '{age} ans • {sex}'],
    'psych_sessions_count': ['{n} جلسة', '{n} séance(s)'],
    'psych_hours': ['ساعات التطوع', 'Heures de bénévolat'],
    'psych_no_items': ['لا شيء هنا حالياً', 'Rien pour le moment'],
    'psych_name_hidden': ['اسم مستعار', 'Pseudonyme'],
    'wd_1': ['الاثنين', 'Lundi'],
    'wd_2': ['الثلاثاء', 'Mardi'],
    'wd_3': ['الأربعاء', 'Mercredi'],
    'wd_4': ['الخميس', 'Jeudi'],
    'wd_5': ['الجمعة', 'Vendredi'],
    'wd_6': ['السبت', 'Samedi'],
    'wd_7': ['الأحد', 'Dimanche'],
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
