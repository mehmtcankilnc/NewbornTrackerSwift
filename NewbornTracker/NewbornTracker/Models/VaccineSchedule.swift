import Foundation

/// A simplified version of Turkey's national immunization schedule (T.C. Sağlık Bakanlığı).
/// Approximate on purpose: the screen tells parents to confirm the exact schedule with their pediatrician.
enum VaccineSchedule {
    static let items: [ScheduleItem] = [
        ScheduleItem(id: "hepb-birth", age: "At birth", name: "Hepatitis B (dose 1)"),
        ScheduleItem(id: "bcg-2m", age: "Month 2", name: "BCG (tuberculosis)"),
        ScheduleItem(id: "dabt-ipa-hib-2m", age: "Month 2", name: "DTaP-IPV-Hib (dose 1)"),
        ScheduleItem(id: "kpa-2m", age: "Month 2", name: "Pneumococcal conjugate (dose 1)"),
        ScheduleItem(id: "hepb-4m", age: "Month 4", name: "Hepatitis B (dose 2)"),
        ScheduleItem(id: "dabt-ipa-hib-4m", age: "Month 4", name: "DTaP-IPV-Hib (dose 2)"),
        ScheduleItem(id: "kpa-4m", age: "Month 4", name: "Pneumococcal conjugate (dose 2)"),
        ScheduleItem(id: "dabt-ipa-hib-6m", age: "Month 6", name: "DTaP-IPV-Hib (dose 3)"),
        ScheduleItem(id: "hepb-6m", age: "Month 6", name: "Hepatitis B (dose 3)"),
        ScheduleItem(id: "kpa-12m", age: "Month 12", name: "Pneumococcal conjugate (booster)"),
        ScheduleItem(id: "kkk-12m", age: "Month 12", name: "MMR - Measles, Mumps, Rubella (dose 1)"),
        ScheduleItem(id: "sucicegi-12m", age: "Month 12", name: "Varicella (dose 1)"),
        ScheduleItem(id: "hepa-18m", age: "Month 18", name: "Hepatitis A (dose 1)"),
        ScheduleItem(id: "dabt-ipa-hib-18m", age: "Month 18", name: "DTaP-IPV-Hib (booster)"),
        ScheduleItem(id: "opa-18m", age: "Month 18", name: "OPV - Oral Polio (dose 1)"),
        ScheduleItem(id: "hepa-24m", age: "Month 24", name: "Hepatitis A (dose 2)"),
        ScheduleItem(id: "dabt-ipa-1sinif", age: "1st grade", name: "DTaP-IPV (booster)"),
        ScheduleItem(id: "kkk-1sinif", age: "1st grade", name: "MMR (dose 2)"),
        ScheduleItem(id: "opa-1sinif", age: "1st grade", name: "OPV (dose 2)"),
        ScheduleItem(id: "td-8sinif", age: "8th grade", name: "Td (Tetanus-Diphtheria) booster"),
    ]
}
