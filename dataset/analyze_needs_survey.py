#!/usr/bin/env python3
"""Reproducible aggregate analysis for NALA's pre-adoption needs survey."""

from __future__ import annotations

import csv
import json
import math
import statistics
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'dataset/Survei Kebutuhan Aplikasi Pengelolaan Keuangan Mahasiswa (Jawaban) - Form Responses 1.csv'
OUT = ROOT / 'docs/evaluation/survey'


def split_choices(value: str) -> list[str]:
    return [item.strip() for item in value.split(',') if item.strip()]


def pct(count: int, total: int) -> float:
    return round(count * 100 / total, 1) if total else 0.0


def likert_summary(rows: list[dict[str, str]], header: str) -> dict[str, float | int]:
    values = [int(row[header]) for row in rows if row[header].strip().isdigit()]
    return {
        'n': len(values),
        'mean': round(statistics.mean(values), 2),
        'median': statistics.median(values),
        'top2_count': sum(value >= 4 for value in values),
        'top2_percent': pct(sum(value >= 4 for value in values), len(values)),
    }


with SOURCE.open(encoding='utf-8-sig', newline='') as stream:
    all_rows = list(csv.DictReader(stream))

active_header = 'Apakah Anda mahasiswa aktif?'
rows = [row for row in all_rows if row[active_header].strip().lower() == 'ya']
n = len(rows)

headers = list(all_rows[0])
q = {index: headers[index] for index in range(1, len(headers))}

age_values = []
for row in rows:
    digits = ''.join(character for character in row[q[2]] if character.isdigit())
    if digits:
        age_values.append(int(digits))

media_counts = Counter(row[q[5]].strip() for row in rows if row[q[5]].strip())
recording_counts = Counter(row[q[6]].strip() for row in rows if row[q[6]].strip())
budget_counts = Counter(row[q[7]].strip() for row in rows if row[q[7]].strip())

barriers = Counter()
barrier_over_limit = 0
for row in rows:
    selected = split_choices(row[q[8]])
    barriers.update(selected)
    barrier_over_limit += len(selected) > 3

features = Counter()
feature_over_limit = 0
for row in rows:
    selected = split_choices(row[q[14]])
    features.update(selected)
    feature_over_limit += len(selected) > 3

problem_items = {q[index]: likert_summary(rows, q[index]) for index in range(9, 14)}

interest_scale = {
    'Sangat tidak tertarik': 1,
    'Tidak tertarik': 2,
    'Netral': 3,
    'Tertarik': 4,
    'Sangat tertarik': 5,
}


def interest_summary(header: str) -> dict[str, float | int]:
    values = [interest_scale[row[header].strip()] for row in rows if row[header].strip() in interest_scale]
    return {
        'n': len(values),
        'mean': round(statistics.mean(values), 2),
        'top2_count': sum(value >= 4 for value in values),
        'top2_percent': pct(sum(value >= 4 for value in values), len(values)),
    }


intent = [int(row[q[17]]) for row in rows if row[q[17]].strip().isdigit()]

summary = {
    'source_responses': len(all_rows),
    'included_active_students': n,
    'excluded_non_students': len(all_rows) - n,
    'age': {
        'n': len(age_values),
        'min': min(age_values),
        'max': max(age_values),
        'median': statistics.median(age_values),
    },
    'three_or_more_payment_media': {
        'count': sum(count for label, count in media_counts.items() if label in {'3', '4 atau lebih'}),
        'percent': pct(sum(count for label, count in media_counts.items() if label in {'3', '4 atau lebih'}), n),
    },
    'records_occasionally_or_never': {
        'count': recording_counts['Hanya sesekali'] + recording_counts['Tidak pernah'],
        'percent': pct(recording_counts['Hanya sesekali'] + recording_counts['Tidak pernah'], n),
    },
    'budgets_occasionally_or_never': {
        'count': budget_counts['Kadang-kadang'] + budget_counts['Tidak pernah'],
        'percent': pct(budget_counts['Kadang-kadang'] + budget_counts['Tidak pernah'], n),
    },
    'problem_items': problem_items,
    'barriers': [{'label': label, 'count': count, 'percent': pct(count, n)} for label, count in barriers.most_common()],
    'features': [{'label': label, 'count': count, 'percent': pct(count, n)} for label, count in features.most_common()],
    'scan_interest': interest_summary(q[15]),
    'ai_coach_interest': interest_summary(q[16]),
    'trial_intention': {
        'n': len(intent),
        'mean': round(statistics.mean(intent), 2),
        'median': statistics.median(intent),
        'score_7_plus_count': sum(value >= 7 for value in intent),
        'score_7_plus_percent': pct(sum(value >= 7 for value in intent), len(intent)),
        'score_8_plus_count': sum(value >= 8 for value in intent),
        'score_8_plus_percent': pct(sum(value >= 8 for value in intent), len(intent)),
    },
    'quality_notes': {
        'barrier_responses_over_stated_limit': barrier_over_limit,
        'feature_responses_over_stated_limit': feature_over_limit,
        'missing_by_question': {
            str(index): sum(not row[q[index]].strip() for row in rows)
            for index in range(1, 18)
        },
    },
}

OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'needs_survey_summary.json').write_text(
    json.dumps(summary, indent=2, ensure_ascii=False) + '\n', encoding='utf-8'
)

short_problem_labels = {
    q[9]: 'Tidak mengetahui alokasi uang',
    q[10]: 'Lupa mencatat transaksi kecil',
    q[11]: 'Dana habis lebih cepat',
    q[12]: 'Sulit mengontrol banyak media',
    q[13]: 'Membutuhkan peringatan budget',
}


def md_table(rows_: list[tuple[str, str, str]]) -> str:
    body = ['| Indikator | Hasil | Interpretasi |', '|---|---:|---|']
    body.extend(f'| {a} | {b} | {c} |' for a, b, c in rows_)
    return '\n'.join(body)


problem_table = []
for header, stats in problem_items.items():
    problem_table.append((
        short_problem_labels[header],
        f"{stats['top2_count']}/{stats['n']} ({stats['top2_percent']}%)",
        f"Rerata {stats['mean']}/5",
    ))

feature_table = [
    (item['label'], f"{item['count']}/{n} ({item['percent']}%)", 'Pilihan majemuk')
    for item in summary['features'][:6]
]

report = f'''# Hasil Survei Kebutuhan NALA

## Metode dan posisi analisis

Survei pra-penggunaan ini mengumpulkan {len(all_rows)} respons. Analisis utama
menggunakan {n} mahasiswa aktif; dua responden nonmahasiswa dikeluarkan sesuai
target pengguna. Instrumen mengukur konteks, masalah, kebutuhan fitur, minat,
dan niat mencoba. Instrumen ini **bukan pengujian TAM/UTAUT**, karena tidak
memiliki beberapa butir untuk setiap konstruk penerimaan. UTAUT dapat digunakan
pada studi lanjutan setelah responden mencoba prototipe.

## Temuan utama

- {summary['three_or_more_payment_media']['count']}/{n} ({summary['three_or_more_payment_media']['percent']}%) menggunakan minimal tiga media pembayaran/penyimpanan.
- {summary['records_occasionally_or_never']['count']}/{n} ({summary['records_occasionally_or_never']['percent']}%) hanya sesekali atau tidak pernah mencatat transaksi.
- {summary['budgets_occasionally_or_never']['count']}/{n} ({summary['budgets_occasionally_or_never']['percent']}%) hanya kadang-kadang atau tidak pernah membuat budget bulanan.
- Minat positif terhadap scan struk: {summary['scan_interest']['top2_count']}/{summary['scan_interest']['n']} ({summary['scan_interest']['top2_percent']}%).
- Minat positif terhadap AI Financial Coach: {summary['ai_coach_interest']['top2_count']}/{summary['ai_coach_interest']['n']} ({summary['ai_coach_interest']['top2_percent']}%).
- Niat mencoba NALA memiliki rerata {summary['trial_intention']['mean']}/10; {summary['trial_intention']['score_7_plus_count']}/{summary['trial_intention']['n']} ({summary['trial_intention']['score_7_plus_percent']}%) memberi skor minimal 7.

{md_table(problem_table)}

## Prioritas fitur

{md_table(feature_table)}

## Kualitas dan batasan data

- Tiga respons tidak mengisi semester dan satu respons tidak mengisi niat mencoba; butir analisis lain lengkap pada sampel mahasiswa aktif.
- Pertanyaan hambatan dan fitur menyebut batas maksimal tiga, tetapi konfigurasi formulir tidak menegakkan batas tersebut: {barrier_over_limit} respons hambatan dan {feature_over_limit} respons fitur memilih lebih dari tiga. Karena itu hasil multi-pilihan diperlakukan sebagai frekuensi eksploratif, bukan ranking eksklusif.
- Sampel bersifat convenience sampling dan didominasi mahasiswa semester 7–8; hasil belum dapat digeneralisasi ke seluruh mahasiswa Indonesia.
- Data menunjukkan kebutuhan dan minat awal, bukan efektivitas NALA, usability setelah penggunaan, atau hubungan kausal.
'''
(OUT / 'needs_survey_results.md').write_text(report, encoding='utf-8')

# Compact SVG used in the proposal; no respondent-level data is exposed.
problem_bars = [(short_problem_labels[h], s['top2_percent']) for h, s in problem_items.items()]
short_feature_labels = {
    'Pencatatan transaksi melalui chat AI': 'Pencatatan melalui chat AI',
    'Peringatan batas pengeluaran': 'Peringatan batas pengeluaran',
    'Laporan keuangan bulanan': 'Laporan keuangan bulanan',
}
feature_bars = [
    (short_feature_labels.get(item['label'], item['label']), item['percent'])
    for item in summary['features'][:6]
]


def svg_bar_group(items, x, y, width, title):
    parts = [f'<text x="{x}" y="{y}" class="title">{title}</text>']
    bar_x = x + 235
    bar_width = width - 300
    for index, (label, value) in enumerate(items):
        row_y = y + 38 + index * 42
        fill = bar_width * value / 100
        parts.extend([
            f'<text x="{x}" y="{row_y + 15}" class="label">{label}</text>',
            f'<rect x="{bar_x}" y="{row_y}" width="{bar_width}" height="18" rx="5" fill="#E2E8F0"/>',
            f'<rect x="{bar_x}" y="{row_y}" width="{fill:.1f}" height="18" rx="5" fill="#F97316"/>',
            f'<text x="{bar_x + bar_width + 10}" y="{row_y + 15}" class="value">{value:.1f}%</text>',
        ])
    return ''.join(parts)


svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="650" viewBox="0 0 1200 650">
<rect width="1200" height="650" fill="white"/>
<style>
.title{{font:700 22px Arial,sans-serif;fill:#111827}} .label{{font:16px Arial,sans-serif;fill:#334155}}
.value{{font:700 16px Arial,sans-serif;fill:#111827}}
</style>
{svg_bar_group(problem_bars, 45, 45, 1110, 'Indikator masalah — persentase jawaban 4–5')}
{svg_bar_group(feature_bars, 45, 325, 1110, 'Enam fitur paling banyak dipilih')}
<text x="45" y="625" class="label">n={n} mahasiswa aktif • fitur merupakan pertanyaan multi-pilihan</text>
</svg>'''
(OUT / 'needs-survey-overview.svg').write_text(svg, encoding='utf-8')

print(json.dumps(summary, ensure_ascii=False, indent=2))
