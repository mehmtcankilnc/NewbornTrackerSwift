// WHO Child Growth Standards (2006), LMS parameters at 0, 1, 2, 3, 6, 9, 12, 15, 18, 21 and 24 months.
// Source: WHO Multicentre Growth Reference Study Group, https://www.who.int/tools/child-growth-standards/standards
// Only a subset of the monthly table is kept: the curves are smooth, so linear interpolation between
// these points is visually indistinguishable from the full table.

/// The WHO reference table, looked up by metric and gender. Percentile math lives in WhoPercentiles.
enum WhoGrowthStandards {
    static let table: [GrowthMetric: [Gender: [LmsPoint]]] = [
        .weight: [
            .male: [
                LmsPoint(months: 0, l: 0.3487, m: 3.3464, s: 0.14602),
                LmsPoint(months: 1, l: 0.2297, m: 4.4709, s: 0.13395),
                LmsPoint(months: 2, l: 0.197, m: 5.5675, s: 0.12385),
                LmsPoint(months: 3, l: 0.1738, m: 6.3762, s: 0.11727),
                LmsPoint(months: 6, l: 0.1257, m: 7.934, s: 0.10958),
                LmsPoint(months: 9, l: 0.0917, m: 8.9014, s: 0.10881),
                LmsPoint(months: 12, l: 0.0644, m: 9.6479, s: 0.10925),
                LmsPoint(months: 15, l: 0.0413, m: 10.3108, s: 0.11007),
                LmsPoint(months: 18, l: 0.0211, m: 10.9385, s: 0.11119),
                LmsPoint(months: 21, l: 0.0029, m: 11.5486, s: 0.11261),
                LmsPoint(months: 24, l: -0.0137, m: 12.1515, s: 0.11426),
            ],
            .female: [
                LmsPoint(months: 0, l: 0.3809, m: 3.2322, s: 0.14171),
                LmsPoint(months: 1, l: 0.1714, m: 4.1873, s: 0.13724),
                LmsPoint(months: 2, l: 0.0962, m: 5.1282, s: 0.13),
                LmsPoint(months: 3, l: 0.0402, m: 5.8458, s: 0.12619),
                LmsPoint(months: 6, l: -0.0756, m: 7.297, s: 0.12204),
                LmsPoint(months: 9, l: -0.1507, m: 8.2254, s: 0.12199),
                LmsPoint(months: 12, l: -0.2024, m: 8.9481, s: 0.12268),
                LmsPoint(months: 15, l: -0.2384, m: 9.6008, s: 0.12299),
                LmsPoint(months: 18, l: -0.2637, m: 10.2315, s: 0.12309),
                LmsPoint(months: 21, l: -0.2815, m: 10.8534, s: 0.12335),
                LmsPoint(months: 24, l: -0.2941, m: 11.4775, s: 0.1239),
            ],
        ],
        .height: [
            .male: [
                LmsPoint(months: 0, l: 1, m: 49.8842, s: 0.03795),
                LmsPoint(months: 1, l: 1, m: 54.7244, s: 0.03557),
                LmsPoint(months: 2, l: 1, m: 58.4249, s: 0.03424),
                LmsPoint(months: 3, l: 1, m: 61.4292, s: 0.03328),
                LmsPoint(months: 6, l: 1, m: 67.6236, s: 0.03165),
                LmsPoint(months: 9, l: 1, m: 71.9687, s: 0.03117),
                LmsPoint(months: 12, l: 1, m: 75.7488, s: 0.03137),
                LmsPoint(months: 15, l: 1, m: 79.1458, s: 0.03197),
                LmsPoint(months: 18, l: 1, m: 82.2587, s: 0.03279),
                LmsPoint(months: 21, l: 1, m: 85.1348, s: 0.03376),
                LmsPoint(months: 24, l: 1, m: 87.8161, s: 0.03479),
            ],
            .female: [
                LmsPoint(months: 0, l: 1, m: 49.1477, s: 0.0379),
                LmsPoint(months: 1, l: 1, m: 53.6872, s: 0.0364),
                LmsPoint(months: 2, l: 1, m: 57.0673, s: 0.03568),
                LmsPoint(months: 3, l: 1, m: 59.8029, s: 0.0352),
                LmsPoint(months: 6, l: 1, m: 65.7311, s: 0.03448),
                LmsPoint(months: 9, l: 1, m: 70.1435, s: 0.03444),
                LmsPoint(months: 12, l: 1, m: 74.015, s: 0.03479),
                LmsPoint(months: 15, l: 1, m: 77.5099, s: 0.03534),
                LmsPoint(months: 18, l: 1, m: 80.7079, s: 0.03598),
                LmsPoint(months: 21, l: 1, m: 83.6654, s: 0.03666),
                LmsPoint(months: 24, l: 1, m: 86.4153, s: 0.03734),
            ],
        ],
        .headCircumference: [
            .male: [
                LmsPoint(months: 0, l: 1, m: 34.4618, s: 0.03686),
                LmsPoint(months: 1, l: 1, m: 37.2759, s: 0.03133),
                LmsPoint(months: 2, l: 1, m: 39.1285, s: 0.02997),
                LmsPoint(months: 3, l: 1, m: 40.5135, s: 0.02918),
                LmsPoint(months: 6, l: 1, m: 43.3306, s: 0.02817),
                LmsPoint(months: 9, l: 1, m: 44.9998, s: 0.02792),
                LmsPoint(months: 12, l: 1, m: 46.0661, s: 0.02791),
                LmsPoint(months: 15, l: 1, m: 46.806, s: 0.02801),
                LmsPoint(months: 18, l: 1, m: 47.3711, s: 0.02816),
                LmsPoint(months: 21, l: 1, m: 47.8408, s: 0.02835),
                LmsPoint(months: 24, l: 1, m: 48.2515, s: 0.02856),
            ],
            .female: [
                LmsPoint(months: 0, l: 1, m: 33.8787, s: 0.03496),
                LmsPoint(months: 1, l: 1, m: 36.5463, s: 0.0321),
                LmsPoint(months: 2, l: 1, m: 38.2521, s: 0.03168),
                LmsPoint(months: 3, l: 1, m: 39.5328, s: 0.0314),
                LmsPoint(months: 6, l: 1, m: 42.1995, s: 0.03093),
                LmsPoint(months: 9, l: 1, m: 43.83, s: 0.03076),
                LmsPoint(months: 12, l: 1, m: 44.8965, s: 0.03076),
                LmsPoint(months: 15, l: 1, m: 45.6553, s: 0.03084),
                LmsPoint(months: 18, l: 1, m: 46.2424, s: 0.03098),
                LmsPoint(months: 21, l: 1, m: 46.7384, s: 0.03115),
                LmsPoint(months: 24, l: 1, m: 47.1822, s: 0.03135),
            ],
        ],
    ]
}
