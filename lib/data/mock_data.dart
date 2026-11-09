import 'package:flutter/material.dart';

import '../models/models.dart';

/// Demo data used until the app is connected to a real backend.
class MockData {
  MockData._();

  static const currentPatientId = 'p1';
  static const currentDoctorId = 'd1';

  static const doctors = <Doctor>[
    Doctor(
      id: 'd1',
      name: 'د. سارة بن علي',
      specialtyId: 'internal',
      yearsOfExperience: 12,
      rating: 4.9,
      consultationsCount: 214,
      city: 'الجزائر',
      cityFr: 'Alger',
      bio: 'أخصائية في الطب الباطني، متطوعة لمساعدة المرضى غير القادرين على الكشف.',
      availability: ['السبت 18:00 - 20:00', 'الثلاثاء 20:00 - 22:00'],
    ),
    Doctor(
      id: 'd2',
      name: 'د. يوسف المنصوري',
      specialtyId: 'cardio',
      yearsOfExperience: 18,
      rating: 4.8,
      consultationsCount: 167,
      city: 'الدار البيضاء',
      cityFr: 'Casablanca',
      bio: 'استشاري أمراض القلب وقراءة تخطيط القلب والإيكو.',
      availability: ['الأحد 19:00 - 21:00'],
    ),
    Doctor(
      id: 'd3',
      name: 'د. مريم حداد',
      specialtyId: 'pediatrics',
      yearsOfExperience: 9,
      rating: 4.9,
      consultationsCount: 301,
      city: 'تونس',
      cityFr: 'Tunis',
      bio: 'طبيبة أطفال، أهتم بتغذية الطفل والتطعيمات.',
      availability: ['يومياً 21:00 - 22:00'],
    ),
    Doctor(
      id: 'd4',
      name: 'د. كريم العمري',
      specialtyId: 'radiology',
      yearsOfExperience: 15,
      rating: 4.7,
      consultationsCount: 122,
      city: 'وهران',
      cityFr: 'Oran',
      bio: 'أخصائي أشعة: قراءة صور الأشعة السينية والرنين والسكانر.',
      available: false,
      availability: ['الجمعة 10:00 - 12:00'],
    ),
    Doctor(
      id: 'd5',
      name: 'د. نور الهدى زروقي',
      specialtyId: 'gyneco',
      yearsOfExperience: 11,
      rating: 4.8,
      consultationsCount: 189,
      city: 'قسنطينة',
      cityFr: 'Constantine',
      bio: 'أخصائية نساء وتوليد ومتابعة الحمل.',
      availability: ['الإثنين 20:00 - 22:00'],
    ),
    Doctor(
      id: 'd6',
      name: 'د. أحمد بلقاسم',
      specialtyId: 'endo',
      yearsOfExperience: 20,
      rating: 4.9,
      consultationsCount: 256,
      city: 'الرباط',
      cityFr: 'Rabat',
      bio: 'استشاري السكري والغدد الصماء، قراءة تحاليل السكر التراكمي والغدة الدرقية.',
      availability: ['الأربعاء 18:00 - 20:00'],
    ),
    Doctor(
      id: 'd7',
      name: 'د. ليلى بوزيد',
      specialtyId: 'derma',
      yearsOfExperience: 7,
      rating: 4.6,
      consultationsCount: 98,
      city: 'سطيف',
      cityFr: 'Sétif',
      bio: 'طبيبة جلدية، أستقبل الاستشارات المصورة.',
      availability: ['الخميس 19:00 - 21:00'],
    ),
    Doctor(
      id: 'd8',
      name: 'د. عمر الشريف',
      specialtyId: 'general',
      yearsOfExperience: 5,
      rating: 4.7,
      consultationsCount: 143,
      city: 'عنابة',
      cityFr: 'Annaba',
      bio: 'طبيب عام، أساعد في توجيه المرضى إلى التخصص المناسب.',
      availability: ['يومياً 22:00 - 23:00'],
    ),
  ];

  static Doctor? doctorById(String? id) {
    if (id == null) return null;
    for (final d in doctors) {
      if (d.id == id) return d;
    }
    return null;
  }

  static List<Consultation> consultations() {
    final now = DateTime.now();
    return [
      Consultation(
        id: 'c1',
        patientId: currentPatientId,
        patientName: 'محمد الأمين',
        patientAge: 54,
        patientMale: true,
        chronicDiseases: const ['cd_diabetes'],
        specialtyId: 'endo',
        type: ConsultationType.lab,
        urgency: Urgency.soon,
        symptoms: 'أجريت تحليل السكر التراكمي وكانت النتيجة 8.9%. أشعر بعطش كثير وتعب في المساء. أتناول دواء الميتفورمين.',
        durationKey: 'dur_months',
        attachments: const [
          Attachment('تحليل_HbA1c.jpg', AttachmentKind.image),
          Attachment('وظائف_الكلى.pdf', AttachmentKind.pdf),
        ],
        status: ConsultationStatus.answered,
        createdAt: now.subtract(const Duration(days: 3)),
        doctorId: 'd6',
        reply: DoctorReply(
          findings: 'السكر التراكمي 8.9% أعلى من الهدف (أقل من 7%). وظائف الكلى ضمن الطبيعي.',
          diagnosis: 'سكري من النوع الثاني غير منضبط بشكل كافٍ.',
          recommendations: 'الالتزام بالحمية وتقليل السكريات والخبز الأبيض، المشي 30 دقيقة يومياً، ومراجعة طبيبك لتعديل جرعة الدواء. إعادة التحليل بعد 3 أشهر.',
          needsVisit: true,
          date: now.subtract(const Duration(days: 2)),
        ),
        messages: [
          ChatMessage(
            fromDoctor: true,
            text: 'مرحباً، اطلعت على تحاليلك وكتبت لك الرد. هل لديك أي سؤال؟',
            time: now.subtract(const Duration(days: 2, hours: 1)),
          ),
          ChatMessage(
            fromDoctor: false,
            text: 'شكراً دكتور، هل يمكنني تناول الفواكه؟',
            time: now.subtract(const Duration(days: 2)),
          ),
          ChatMessage(
            fromDoctor: true,
            text: 'نعم بكميات معتدلة، ويفضل التفاح والبرتقال بدل العصير.',
            time: now.subtract(const Duration(days: 1, hours: 20)),
          ),
        ],
      ),
      Consultation(
        id: 'c2',
        patientId: currentPatientId,
        patientName: 'محمد الأمين',
        patientAge: 54,
        patientMale: true,
        chronicDiseases: const ['cd_diabetes'],
        specialtyId: 'cardio',
        type: ConsultationType.general,
        urgency: Urgency.normal,
        symptoms: 'خفقان في القلب أحياناً عند صعود الدرج، مع ضيق بسيط في التنفس يزول بالراحة.',
        durationKey: 'dur_weeks',
        attachments: const [
          Attachment('تخطيط_القلب.jpg', AttachmentKind.image),
        ],
        status: ConsultationStatus.accepted,
        createdAt: now.subtract(const Duration(hours: 9)),
        doctorId: 'd2',
      ),
      Consultation(
        id: 'c3',
        patientId: 'p2',
        patientName: 'فاطمة الزهراء',
        patientAge: 37,
        patientMale: false,
        hideName: true,
        chronicDiseases: const [],
        specialtyId: 'internal',
        type: ConsultationType.lab,
        urgency: Urgency.urgent,
        symptoms: 'تعب شديد ودوخة وشحوب. تحليل الدم يظهر هيموغلوبين 8.1. لا أستطيع الذهاب للطبيب حالياً.',
        durationKey: 'dur_weeks',
        attachments: const [
          Attachment('تحليل_الدم_CBC.jpg', AttachmentKind.image),
          Attachment('مخزون_الحديد.jpg', AttachmentKind.image),
        ],
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
      Consultation(
        id: 'c4',
        patientId: 'p3',
        patientName: 'عبد الرحمن قاسمي',
        patientAge: 66,
        patientMale: true,
        chronicDiseases: const ['cd_hypertension', 'cd_kidney'],
        specialtyId: 'internal',
        type: ConsultationType.lab,
        urgency: Urgency.soon,
        symptoms: 'ارتفاع في نسبة الكرياتينين في التحليل الأخير، مع تورم خفيف في القدمين.',
        durationKey: 'dur_months',
        attachments: const [Attachment('وظائف_الكلى.pdf', AttachmentKind.pdf)],
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Consultation(
        id: 'c5',
        patientId: 'p4',
        patientName: 'خديجة بن يوسف',
        patientAge: 29,
        patientMale: false,
        specialtyId: 'internal',
        type: ConsultationType.general,
        urgency: Urgency.normal,
        symptoms: 'آلام في المعدة بعد الأكل مع حرقة، خاصة في الليل.',
        durationKey: 'dur_weeks',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Consultation(
        id: 'c6',
        patientId: 'p5',
        patientName: 'إلياس مرابط',
        patientAge: 8,
        patientMale: true,
        specialtyId: 'pediatrics',
        type: ConsultationType.general,
        urgency: Urgency.soon,
        symptoms: 'ابني عمره 8 سنوات، سعال مستمر منذ أسبوعين خاصة في الليل.',
        durationKey: 'dur_weeks',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      Consultation(
        id: 'c7',
        patientId: 'p6',
        patientName: 'رشيد بن عمار',
        patientAge: 45,
        patientMale: true,
        specialtyId: 'internal',
        type: ConsultationType.lab,
        urgency: Urgency.normal,
        symptoms: 'ارتفاع الدهون الثلاثية والكوليسترول في التحاليل الدورية.',
        durationKey: 'dur_years',
        attachments: const [
          Attachment('تحليل_الدهون.jpg', AttachmentKind.image),
        ],
        status: ConsultationStatus.accepted,
        createdAt: now.subtract(const Duration(days: 1)),
        doctorId: currentDoctorId,
        messages: [
          ChatMessage(
            fromDoctor: false,
            text: 'شكراً دكتورة على قبول حالتي.',
            time: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),
      Consultation(
        id: 'c8',
        patientId: 'p7',
        patientName: 'سعاد مزياني',
        patientAge: 58,
        patientMale: false,
        chronicDiseases: const ['cd_hypertension'],
        specialtyId: 'internal',
        type: ConsultationType.lab,
        urgency: Urgency.normal,
        symptoms: 'نتيجة تحليل الغدة الدرقية TSH مرتفعة قليلاً.',
        durationKey: 'dur_months',
        status: ConsultationStatus.answered,
        createdAt: now.subtract(const Duration(days: 5)),
        doctorId: currentDoctorId,
        rating: 5,
        reply: DoctorReply(
          findings: 'TSH = 6.2 مع T4 طبيعي.',
          diagnosis: 'قصور غدة درقية تحت سريري محتمل.',
          recommendations:
              'إعادة التحليل بعد 6 أسابيع مع تحليل الأجسام المضادة.',
          needsVisit: false,
          date: now.subtract(const Duration(days: 4)),
        ),
      ),
    ];
  }

  static List<AppNotification> notifications(bool forDoctor) {
    final now = DateTime.now();
    if (forDoctor) {
      return [
        AppNotification(
          icon: Icons.priority_high_rounded,
          title: 'طلب مستعجل جديد',
          body: 'حالة فقر دم في تخصص الباطنية تنتظر طبيباً.',
          time: now.subtract(const Duration(minutes: 40)),
        ),
        AppNotification(
          icon: Icons.chat_bubble_outline,
          title: 'رسالة جديدة',
          body: 'رشيد بن عمار: شكراً دكتورة على قبول حالتي.',
          time: now.subtract(const Duration(hours: 20)),
        ),
        AppNotification(
          icon: Icons.star_outline,
          title: 'تقييم جديد ⭐⭐⭐⭐⭐',
          body: 'سعاد مزياني: جزاك الله خيراً على وقتك.',
          time: now.subtract(const Duration(days: 4)),
          read: true,
        ),
      ];
    }
    return [
      AppNotification(
        icon: Icons.how_to_reg_outlined,
        title: 'تم قبول طلبك',
        body: 'د. يوسف المنصوري يراجع استشارتك الآن.',
        time: now.subtract(const Duration(hours: 8)),
      ),
      AppNotification(
        icon: Icons.mark_email_read_outlined,
        title: 'وصلك رد الطبيب',
        body: 'رد د. أحمد بلقاسم على استشارة تحليل السكر.',
        time: now.subtract(const Duration(days: 2)),
        read: true,
      ),
      AppNotification(
        icon: Icons.volunteer_activism_outlined,
        title: 'مرحباً بك في شِفاءٌ لِلنّاس',
        body: 'أكمل ملفك الصحي لتساعد الأطباء على فهم حالتك.',
        time: now.subtract(const Duration(days: 4)),
        read: true,
      ),
    ];
  }
}
