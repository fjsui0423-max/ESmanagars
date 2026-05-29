#!/usr/bin/env python3
"""
generate_demo_data.py  v3
App Store screenshot demo data — 20 standalone companies, all 本選考.

Scheduling design
──────────────────────────────────────────────────────────────────────────────
• ES deadlines  : biased toward Sunday / Monday
                  (Mar 29 Sun, Apr 5 Sun, Apr 6 Mon, Apr 12 Sun, Apr 13 Mon,
                   Apr 19 Sun, Apr 20 Mon, Apr 26 Sun, May 3 Sun, May 4 Mon)
• Phase mixing  : fast companies (外資/ベンチャー想定) reach 1次面接 by
                  mid-April; slow companies (日系大手想定) still doing ES/apt
                  through May
• 同時提出       : C, D, G, H — ES deadline == apt deadline (same datetime)
• ES↔apt overlap : fast companies' apt tests run in early April while medium
                  companies are still submitting ES (gradient overlap)

Result distribution  (total 20)
  ES落選 ×2 / apt落選 ×2 / 1次落選 ×2 / 2次落選 ×8
  最終落選 ×3 / 内定 ×3
──────────────────────────────────────────────────────────────────────────────
"""

import json, uuid, os
from datetime import datetime, timezone
from collections import Counter

# ─── Helpers ─────────────────────────────────────────────────────────────────

def uid():
    return str(uuid.uuid4())

def iso(year, month, day, hour=23, minute=59):
    """Default 23:59 for deadlines. Pass explicit hour/minute for interviews."""
    return datetime(year, month, day, hour, minute, 0,
                    tzinfo=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# ─── DTO factories ────────────────────────────────────────────────────────────

ES_ANSWER_MOTIVATION = (
    "貴社を志望する理由は3点あります。"
    "第一に、業界随一の技術力と実績。"
    "第二に、若手社員が裁量を持って挑戦できる社風。"
    "第三に、グローバルに事業を展開する成長性です。"
    "学生時代に培った〇〇の経験を活かし、貴社の発展に貢献したいと考えています。"
)
ES_ANSWER_GAKUCHIKA = (
    "ゼミでのフィールドワーク調査に最も注力しました。"
    "10名のチームリーダーとして、データ収集から分析・発表まで一貫して担当。"
    "意見の対立を調整しながら成果を出した経験から、"
    "傾聴力と課題解決力を養いました。"
)

def make_es(deadline_iso, status):
    qs = []
    if status in ("提出済み", "合格", "落選"):
        qs = [
            {"id": uid(),
             "questionText": "志望動機を教えてください。（400字以内）",
             "maxLength": 400, "currentAnswer": ES_ANSWER_MOTIVATION,
             "sortOrder": 0, "versions": []},
            {"id": uid(),
             "questionText": "学生時代に最も力を入れたことを教えてください。（300字以内）",
             "maxLength": 300, "currentAnswer": ES_ANSWER_GAKUCHIKA,
             "sortOrder": 1, "versions": []},
        ]
    return {
        "id": uid(), "title": "本選考ES",
        "deadlineAt": deadline_iso, "status": status,
        "questions": qs,
    }

def make_apt(apt_type, deadline_iso, status):
    return {
        "id": uid(), "type": apt_type, "customType": None,
        "deadlineAt": deadline_iso, "status": status,
    }

def make_iv(stage, date_iso, mode, status):
    return {
        "id": uid(), "stage": stage, "startAt": date_iso,
        "mode": mode, "status": status,
    }

def make_sel(sel_status, es, apts, interviews):
    return {
        "id": uid(), "category": "本選考", "title": None,
        "status": sel_status,
        "esBoxes": [es],
        "aptitudeTests": apts,
        "interviews": interviews,
    }

def make_co(name, sels):
    return {"id": uid(), "name": name, "myPageURL": None,
            "loginID": None, "selections": sels}


# ─── 20 companies ─────────────────────────────────────────────────────────────
#
#  ES deadline day-of-week map (2026, Apr 1 = Wed):
#    Mar 29 Sun │ Apr  5 Sun │ Apr  6 Mon │ Apr 12 Sun │ Apr 13 Mon
#    Apr 19 Sun │ Apr 20 Mon │ Apr 26 Sun │ May  3 Sun │ May  4 Mon
#
#  同時提出 (ES deadline == apt deadline):  C社・D社・G社・H社
#
#  Speed tiers:
#    Fast  (外資/ベンチャー)  : ES by Apr 6,  1次面接 mid-Apr
#    Medium                  : ES Apr 12–20, 1次面接 late Apr–early May
#    Slow  (日系大手)        : ES Apr 26–May 4, 1次面接 late May–Jun

companies = [

    # ══════════════════════════════════════════════════════════════════
    # ES落選  ×2  (A・B)
    # ══════════════════════════════════════════════════════════════════

    # A社: 外資ベンチャー / ES Apr 5 (Sun) → 落選
    make_co("A社", [make_sel("落選",
        make_es(iso(2026, 4, 5), "落選"),
        [], [],
    )]),

    # B社: 日系大手 / ES May 4 (Mon) → 落選（5月でもES段階）
    make_co("B社", [make_sel("落選",
        make_es(iso(2026, 5, 4), "落選"),
        [], [],
    )]),

    # ══════════════════════════════════════════════════════════════════
    # 適性落選  ×2  (C・D) — 両社とも同時提出
    # ══════════════════════════════════════════════════════════════════

    # C社: 同時提出 Apr 5 (Sun) — ES と SPI 締切が同一
    make_co("C社", [make_sel("落選",
        make_es(iso(2026, 4, 5), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 4, 5), "落選")],   # ← 同時提出
        [],
    )]),

    # D社: 同時提出 Apr 13 (Mon) — ES と 玉手箱 締切が同一
    make_co("D社", [make_sel("落選",
        make_es(iso(2026, 4, 13), "合格"),
        [make_apt("玉手箱",   iso(2026, 4, 13), "落選")],  # ← 同時提出
        [],
    )]),

    # ══════════════════════════════════════════════════════════════════
    # 1次落選  ×2  (E・F)
    # ══════════════════════════════════════════════════════════════════

    # E社: 外資 / ES Mar 29 (Sun) → apt Apr 6 (Mon) → 1次 Apr 14 (Tue)
    make_co("E社", [make_sel("落選",
        make_es(iso(2026, 3, 29), "合格"),
        [make_apt("TGWEB",    iso(2026, 4,  6), "合格")],
        [make_iv("1次面接", iso(2026, 4, 14, 10, 0), "オンライン", "落選")],
    )]),

    # F社: 中規模 / ES Apr 12 (Sun) → apt Apr 19 (Sun) → 1次 Apr 28 (Tue)
    make_co("F社", [make_sel("落選",
        make_es(iso(2026, 4, 12), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 4, 19), "合格")],
        [make_iv("1次面接", iso(2026, 4, 28, 14, 0), "オンライン", "落選")],
    )]),

    # ══════════════════════════════════════════════════════════════════
    # 2次落選  ×8  (G〜N)
    # ══════════════════════════════════════════════════════════════════

    # G社: 外資 / 同時提出 Apr 6 (Mon) → 1次 Apr 15 (Wed) → 2次 Apr 22 (Wed)
    make_co("G社", [make_sel("落選",
        make_es(iso(2026, 4, 6), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 4,  6), "合格")],  # ← 同時提出
        [make_iv("1次面接", iso(2026, 4, 15, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 4, 22, 10, 0), "オンライン", "落選")],
    )]),

    # H社: 中規模 / 同時提出 Apr 19 (Sun) → 1次 Apr 28 (Tue) → 2次 May 7 (Thu)
    make_co("H社", [make_sel("落選",
        make_es(iso(2026, 4, 19), "合格"),
        [make_apt("TGWEB",    iso(2026, 4, 19), "合格")],  # ← 同時提出
        [make_iv("1次面接", iso(2026, 4, 28, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5,  7, 14, 0), "オンライン", "落選")],
    )]),

    # I社: 外資ベンチャー / ES Apr 6 (Mon) → apt Apr 12 (Sun)
    #      → 1次 Apr 17 (Fri) → 2次 Apr 24 (Fri)
    make_co("I社", [make_sel("落選",
        make_es(iso(2026, 4, 6), "合格"),
        [make_apt("玉手箱",   iso(2026, 4, 12), "合格")],
        [make_iv("1次面接", iso(2026, 4, 17, 14, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 4, 24, 10, 0), "オンライン", "落選")],
    )]),

    # J社: 中規模 / ES Apr 13 (Mon) → apt Apr 20 (Mon)
    #      → 1次 Apr 27 (Mon) → 2次 May 6 (Wed)
    make_co("J社", [make_sel("落選",
        make_es(iso(2026, 4, 13), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 4, 20), "合格")],
        [make_iv("1次面接", iso(2026, 4, 27, 14, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5,  6, 10, 0), "オンライン", "落選")],
    )]),

    # K社: 中規模 / ES Apr 20 (Mon) → apt Apr 26 (Sun)
    #      → 1次 May 1 (Fri) → 2次 May 8 (Fri)
    make_co("K社", [make_sel("落選",
        make_es(iso(2026, 4, 20), "合格"),
        [make_apt("TGWEB",    iso(2026, 4, 26), "合格")],
        [make_iv("1次面接", iso(2026, 5,  1, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5,  8, 10, 0), "オンライン", "落選")],
    )]),

    # L社: やや遅め / ES Apr 26 (Sun) → apt May 3 (Sun)
    #      → 1次 May 12 (Tue) → 2次 May 19 (Tue)
    make_co("L社", [make_sel("落選",
        make_es(iso(2026, 4, 26), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 5,  3), "合格")],
        [make_iv("1次面接", iso(2026, 5, 12, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5, 19, 14, 0), "オンライン", "落選")],
    )]),

    # M社: 日系大手 / ES May 3 (Sun) → apt May 10 (Sun)
    #      → 1次 May 22 (Fri) → 2次 May 29 (Fri)
    make_co("M社", [make_sel("落選",
        make_es(iso(2026, 5,  3), "合格"),
        [make_apt("玉手箱",   iso(2026, 5, 10), "合格")],
        [make_iv("1次面接", iso(2026, 5, 22, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5, 29, 10, 0), "オンライン", "落選")],
    )]),

    # N社: 日系大手 / ES May 4 (Mon) → apt May 11 (Mon)
    #      → 1次 May 25 (Mon) → 2次 Jun 1 (Mon)
    make_co("N社", [make_sel("落選",
        make_es(iso(2026, 5,  4), "合格"),
        [make_apt("TGWEB",    iso(2026, 5, 11), "合格")],
        [make_iv("1次面接", iso(2026, 5, 25, 14, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 6,  1, 10, 0), "オンライン", "落選")],
    )]),

    # ══════════════════════════════════════════════════════════════════
    # 最終落選  ×3  (O・P・Q)
    # ══════════════════════════════════════════════════════════════════

    # O社: 外資 / ES Mar 29 (Sun) → apt Apr 5 (Sun)
    #      → 1次 Apr 16 (Thu) → 2次 Apr 23 (Thu) → 最終 May 7 (Thu)
    make_co("O社", [make_sel("落選",
        make_es(iso(2026, 3, 29), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 4,  5), "合格")],
        [make_iv("1次面接", iso(2026, 4, 16, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 4, 23, 14, 0), "オンライン", "通過"),
         make_iv("最終面接", iso(2026, 5,  7, 10, 0), "対面",     "落選")],
    )]),

    # P社: 中規模 / ES Apr 12 (Sun) → apt Apr 20 (Mon)
    #      → 1次 Apr 29 (Wed) → 2次 May 8 (Fri) → 最終 May 21 (Thu)
    make_co("P社", [make_sel("落選",
        make_es(iso(2026, 4, 12), "合格"),
        [make_apt("玉手箱",   iso(2026, 4, 20), "合格")],
        [make_iv("1次面接", iso(2026, 4, 29, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5,  8, 14, 0), "オンライン", "通過"),
         make_iv("最終面接", iso(2026, 5, 21, 10, 0), "対面",     "落選")],
    )]),

    # Q社: 日系大手 / ES Apr 26 (Sun) → apt May 3 (Sun)
    #      → 1次 May 14 (Thu) → 2次 May 22 (Fri) → 最終 Jun 3 (Wed)
    make_co("Q社", [make_sel("落選",
        make_es(iso(2026, 4, 26), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 5,  3), "合格")],
        [make_iv("1次面接", iso(2026, 5, 14, 14, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5, 22, 14, 0), "オンライン", "通過"),
         make_iv("最終面接", iso(2026, 6,  3, 10, 0), "対面",     "落選")],
    )]),

    # ══════════════════════════════════════════════════════════════════
    # 内定  ×3  (R・S・T)
    # ══════════════════════════════════════════════════════════════════

    # R社: 外資 / ES Apr 6 (Mon) → apt Apr 13 (Mon)
    #      → 1次 Apr 21 (Tue) → 2次 Apr 28 (Tue) → 最終 May 11 (Mon)
    make_co("R社", [make_sel("内定",
        make_es(iso(2026, 4,  6), "合格"),
        [make_apt("TGWEB",    iso(2026, 4, 13), "合格")],
        [make_iv("1次面接", iso(2026, 4, 21, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 4, 28, 14, 0), "オンライン", "通過"),
         make_iv("最終面接", iso(2026, 5, 11, 10, 0), "対面",     "通過")],
    )]),

    # S社: 中規模 / ES Apr 19 (Sun) → apt Apr 26 (Sun)
    #      → 1次 May 1 (Fri) → 2次 May 12 (Tue) → 最終 May 25 (Mon)
    make_co("S社", [make_sel("内定",
        make_es(iso(2026, 4, 19), "合格"),
        [make_apt("SPI(WEB)", iso(2026, 4, 26), "合格")],
        [make_iv("1次面接", iso(2026, 5,  1, 14, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5, 12, 14, 0), "オンライン", "通過"),
         make_iv("最終面接", iso(2026, 5, 25, 10, 0), "対面",     "通過")],
    )]),

    # T社: 日系大手 / ES May 3 (Sun) → apt May 10 (Sun)
    #      → 1次 May 20 (Wed) → 2次 May 28 (Thu) → 最終 Jun 10 (Wed)
    make_co("T社", [make_sel("内定",
        make_es(iso(2026, 5,  3), "合格"),
        [make_apt("玉手箱",   iso(2026, 5, 10), "合格")],
        [make_iv("1次面接", iso(2026, 5, 20, 10, 0), "オンライン", "通過"),
         make_iv("2次面接", iso(2026, 5, 28, 14, 0), "オンライン", "通過"),
         make_iv("最終面接", iso(2026, 6, 10, 10, 0), "対面",     "通過")],
    )]),
]

# ─── Output ──────────────────────────────────────────────────────────────────

payload = {
    "exportedAt": iso(2026, 6, 15, 12, 0),
    "industries": [],
    "standaloneCompanies": companies,
    "templates": [],
}

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screenshot_demo.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)

# ─── Stats ────────────────────────────────────────────────────────────────────

all_sels = [s for c in companies for s in c["selections"]]
all_es   = [e  for s in all_sels for e  in s["esBoxes"]]
all_apts = [a  for s in all_sels for a  in s["aptitudeTests"]]
all_ivs  = [iv for s in all_sels for iv in s["interviews"]]

WEEKDAYS = ["月", "火", "水", "木", "金", "土", "日"]

print(f"✓  Generated : {out}")
print(f"   Companies : {len(companies)}")
print(f"   Selections: {Counter(s['status'] for s in all_sels)}")
print(f"   ES status : {Counter(e['status'] for e in all_es)}")
print(f"   Apt types : {Counter(a['type'] for a in all_apts)}")
print(f"   Apt status: {Counter(a['status'] for a in all_apts)}")
print(f"   IV status : {Counter(iv['status'] for iv in all_ivs)}")
print(f"   IV mode   : {Counter(iv['mode']   for iv in all_ivs)}")
print(f"   IV stage  : {Counter(iv['stage']  for iv in all_ivs)}")
print()
print("   ES締切 weekday breakdown:")
for co in companies:
    sel = co["selections"][0]
    es  = sel["esBoxes"][0]
    apts = sel["aptitudeTests"]
    d   = datetime.fromisoformat(es["deadlineAt"].replace("Z", "+00:00"))
    wd  = WEEKDAYS[d.weekday()]
    same = any(a["deadlineAt"] == es["deadlineAt"] for a in apts)
    flag = "  ← 同時提出" if same else ""
    print(f"     {co['name']:4s} {d.strftime('%m/%d')} ({wd}){flag}")

es_weekdays = []
for co in companies:
    es = co["selections"][0]["esBoxes"][0]
    d  = datetime.fromisoformat(es["deadlineAt"].replace("Z", "+00:00"))
    es_weekdays.append(WEEKDAYS[d.weekday()])
wd_counter = Counter(es_weekdays)
print()
print(f"   ES締切 曜日集計: {dict(wd_counter)}")
sun_mon = wd_counter.get("日", 0) + wd_counter.get("月", 0)
print(f"   日曜＋月曜 合計: {sun_mon} / {len(companies)} 社")
