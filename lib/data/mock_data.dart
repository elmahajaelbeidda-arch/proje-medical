import 'package:flutter/material.dart';

import '../models/blood.dart';
import '../models/models.dart';
import '../models/registration.dart';

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

  // -------------------------------------------------------------------------
  // Blood donation (demo data, fictitious names and numbers)
  // -------------------------------------------------------------------------

  static List<BloodDonor> bloodDonors() {
    final now = DateTime.now();
    return [
      BloodDonor(
        id: 'bd1',
        name: 'د. سارة بن علي',
        bloodType: 'O-',
        city: 'الجزائر',
        phone: '0550 00 01 11',
        kind: DonorKind.doctor,
        registeredAt: now.subtract(const Duration(days: 60)),
      ),
      BloodDonor(
        id: 'bd2',
        name: 'سمية رحال',
        bloodType: 'A+',
        city: 'الجزائر',
        phone: '0550 00 02 22',
        status: DonorStatus.pending,
        registeredAt: now.subtract(const Duration(hours: 5)),
      ),
      BloodDonor(
        id: 'bd3',
        name: 'ياسين مقراني',
        bloodType: 'O+',
        city: 'وهران',
        phone: '0550 00 03 33',
        registeredAt: now.subtract(const Duration(days: 40)),
      ),
      BloodDonor(
        id: 'bd4',
        name: 'هدى بلعيد',
        bloodType: 'B+',
        city: 'قسنطينة',
        phone: '0550 00 04 44',
        registeredAt: now.subtract(const Duration(days: 35)),
      ),
      BloodDonor(
        id: 'bd5',
        name: 'أنيس طالبي',
        bloodType: 'AB+',
        city: 'الجزائر',
        phone: '0550 00 05 55',
        registeredAt: now.subtract(const Duration(days: 30)),
      ),
      BloodDonor(
        id: 'bd6',
        name: 'ريم بوشامة',
        bloodType: 'O+',
        city: 'الجزائر',
        phone: '0550 00 06 66',
        status: DonorStatus.pending,
        registeredAt: now.subtract(const Duration(days: 1)),
      ),
      BloodDonor(
        id: 'bd7',
        name: 'د. كريم العمري',
        bloodType: 'A-',
        city: 'وهران',
        phone: '0550 00 07 77',
        kind: DonorKind.doctor,
        registeredAt: now.subtract(const Duration(days: 20)),
      ),
      BloodDonor(
        id: 'bd8',
        name: 'نوال عيساوي',
        bloodType: 'B-',
        city: 'عنابة',
        phone: '0550 00 08 88',
        status: DonorStatus.rejected,
        registeredAt: now.subtract(const Duration(days: 10)),
      ),
      BloodDonor(
        id: 'bd9',
        name: 'فريد قادري',
        bloodType: 'O+',
        city: 'الجزائر',
        phone: '0550 00 09 99',
        registeredAt: now.subtract(const Duration(days: 15)),
      ),
      BloodDonor(
        id: 'bd10',
        name: 'ليلى سعدي',
        bloodType: 'A+',
        city: 'وهران',
        phone: '0550 00 10 10',
        available: false,
        registeredAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  static List<BloodRequest> bloodRequests() {
    final now = DateTime.now();
    return [
      // Request of the demo patient (from their profile).
      BloodRequest(
        id: 'br5',
        requesterId: currentPatientId,
        patientName: 'محمد الأمين',
        bloodType: 'O+',
        units: 2,
        hospital: 'مستشفى بني مسوس',
        city: 'الجزائر',
        phone: '0550 12 34 56',
        status: BloodRequestStatus.inProgress,
        note: 'عملية مبرمجة الأسبوع القادم.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      BloodRequest(
        id: 'br1',
        requesterId: 'p8',
        patientName: 'عائشة بن موسى',
        requesterName: 'يوسف بن موسى',
        relation: RequesterRelation.family,
        bloodType: 'O+',
        units: 3,
        hospital: 'مستشفى مصطفى باشا',
        city: 'الجزائر',
        urgent: true,
        phone: '0550 10 20 30',
        contact: ContactMethod.whatsapp,
        note: 'عملية جراحية غداً صباحاً.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      BloodRequest(
        id: 'br2',
        requesterId: 'p9',
        patientName: 'سليم عبادة',
        status: BloodRequestStatus.inProgress,
        bloodType: 'A-',
        units: 2,
        hospital: 'المستشفى الجامعي',
        city: 'سطيف',
        phone: '0550 40 50 60',
        note: 'مريض فقر دم يحتاج نقل دم دوري.',
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      BloodRequest(
        id: 'br3',
        requesterId: 'p10',
        patientName: 'رضا حمودي',
        requesterName: 'سهام حمودي',
        relation: RequesterRelation.family,
        status: BloodRequestStatus.matched,
        assignedDonorIds: const ['bd5'],
        bloodType: 'AB+',
        units: 1,
        hospital: 'مستشفى ابن رشد',
        city: 'عنابة',
        phone: '0550 70 80 90',
        contact: ContactMethod.sms,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      BloodRequest(
        id: 'br4',
        requesterId: 'p11',
        patientName: 'مريم شريف',
        bloodType: 'B+',
        units: 2,
        hospital: 'مستشفى قسنطينة الجامعي',
        city: 'قسنطينة',
        phone: '0550 11 22 33',
        status: BloodRequestStatus.fulfilled,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // New accounts waiting for the committee (fictitious data)
  // -------------------------------------------------------------------------

  static List<Registration> registrations() {
    final now = DateTime.now();
    return [
      Registration(
        id: 'reg11',
        role: UserRole.patient,
        name: 'زينب حمادي',
        phone: '0661 20 30 40',
        idNumber: '109912345678901',
        phoneVerified: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Registration(
        id: 'reg12',
        role: UserRole.patient,
        name: 'عبد القادر بوزيان',
        phone: '0770 11 22 33',
        idNumber: '108765432109876',
        phoneVerified: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Registration(
        id: 'reg13',
        role: UserRole.patient,
        name: 'محمد الأمين',
        phone: '0550 12 34 56',
        idNumber: '109870512304821',
        phoneVerified: true,
        status: ReviewStatus.approved,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Registration(
        id: 'reg21',
        role: UserRole.doctor,
        name: 'د. إيمان بلحاج',
        phone: '0551 98 76 54',
        idNumber: '107654321098765',
        specialtyId: 'pediatrics',
        licenseNumber: 'CNOM-16-04512',
        certificate: const Attachment('diplome.pdf', AttachmentKind.pdf),
        phoneVerified: true,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Registration(
        id: 'reg22',
        role: UserRole.doctor,
        name: 'د. رياض منصوري',
        phone: '0662 45 67 89',
        idNumber: '106543210987654',
        specialtyId: 'cardio',
        licenseNumber: 'CNOM-31-00987',
        certificate: const Attachment('carte_pro.jpg', AttachmentKind.image),
        phoneVerified: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Registration(
        id: 'reg23',
        role: UserRole.doctor,
        name: 'د. سارة بن علي',
        phone: '0550 00 01 11',
        idNumber: '105432109876543',
        specialtyId: 'internal',
        licenseNumber: 'CNOM-16-01234',
        phoneVerified: true,
        status: ReviewStatus.approved,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    ];
  }
}
