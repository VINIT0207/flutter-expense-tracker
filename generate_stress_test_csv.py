import random
from datetime import datetime, timedelta

categories = {
    'Food': [
        ('Swiggy Lunch Box', 'Office lunch meal with drink', False, (150, 450)),
        ('Whole Foods Grocery', 'Weekly fresh vegetables, organic fruits and dairy', True, (1200, 4500)),
        ('Starbucks Latte & Croissant', 'Meeting client over coffee & cookies', False, (350, 850)),
        ('Supermarket Staples', 'Monthly pulses, basmati grains, spices and olive oil', True, (2500, 6500)),
        ('Zomato Weekend Dinner', 'Family gourmet pizza and pasta treat', False, (800, 2400)),
        ('Local Fruit Stall', 'Fresh seasonal Alphonso mangoes and apples', True, (200, 600)),
        ('Blinkit Quick Delivery', 'Midnight craving snacks, chocolate and ice cream', False, (120, 400)),
        ('Fine Dining Restaurant', 'Special anniversary dinner buffet', False, (3000, 9500)),
        ('Chai & Samosa Corner', 'Evening masala tea with team members', True, (40, 150)),
        ('Bakery Artisanal Bread & Pastry', 'Morning bakery supplies and sourdough loaf', True, (180, 500)),
    ],
    'Transport': [
        ('Uber Premier Commute', 'Airport ride terminal 2 business flight', False, (450, 1400)),
        ('Metro Smart Card Recharge', 'Monthly unlimited metro transit card recharge', True, (500, 1000)),
        ('Shell Petrol Station Fuel', 'Full tank unleaded petrol for vehicle', True, (2500, 4800)),
        ('Auto Rickshaw Meter Fare', 'Local city transit to metro station', True, (60, 180)),
        ('Expressway FASTag Toll', 'State expressway toll automated electronic debit', True, (200, 800)),
        ('City Mall Parking Fee', 'Multi-level basement underground parking validation', False, (100, 300)),
        ('Automobile Ceramic Detailing', 'Full interior vacuum, engine degrease and wash', False, (1200, 3500)),
        ('IRCTC Executive Train Ticket', 'Intercity executive AC chair car reservation', True, (950, 2400)),
    ],
    'Shopping': [
        ('Amazon Tech Essentials', 'USB-C multi-port hub, braided cables & adapter', True, (899, 3200)),
        ('Zara Linen Summer Collection', 'Breathable cotton casual button-up shirts', False, (2290, 5990)),
        ('IKEA Modular Desk Organizers', 'Desk cable management units, drawer trays & LED', False, (1499, 7500)),
        ('Nike Marathon Running Shoes', 'Long distance training air zoom cushion sneakers', False, (4999, 12999)),
        ('Uniqlo Airism Essentials', 'Innerwear, cooling undershirts and crew socks', True, (1200, 3500)),
        ('Apple Store MagSafe Battery', 'Official magnetic fast wireless battery pack', False, (8900, 10900)),
        ('Neighborhood Hardware Store', 'Stainless screws, drywall anchors, drill accessories', True, (350, 1200)),
    ],
    'Fun': [
        ('PVR IMAX 3D Recliner Tickets', 'Sci-fi movie premiere with large cheese popcorn', False, (800, 2200)),
        ('Netflix 4K UltraHD Subscription', 'Monthly family tier streaming account', False, (649, 649)),
        ('PlayStation Store RPG Purchase', 'Digital deluxe collector edition open world game', False, (2999, 4999)),
        ('Go-Karting Speedway Grand Prix', 'Weekend competitive racing sessions with group', False, (1500, 3500)),
        ('Concert Live Music Festival', 'Weekend rock concert arena general admission pass', False, (3500, 8500)),
        ('Board Game Pub & Cafe', 'Strategy game night craft beers and nacho platters', False, (650, 1800)),
        ('Spotify Premium Family Plan', 'Annual ad-free multi-user music streaming', False, (1799, 1799)),
    ],
    'Bills': [
        ('Electricity Power Utility', 'Monthly household air conditioning electricity bill', True, (1400, 4800)),
        ('Airtel 5G Fiber Broadband', '1 Gbps symmetrical unlimited high-speed fiber plan', True, (999, 1499)),
        ('Mobile 5G Postpaid Plan', 'Unlimited 5G corporate postpaid phone plan', True, (799, 1299)),
        ('Municipal Water Authority', 'Quarterly residential piped water supply charges', True, (350, 850)),
        ('Society Apartment Maintenance', 'Monthly housing security, backup generator & lift fee', True, (3200, 5500)),
        ('LPG Cooking Gas Cylinder Refill', 'Indane domestic LPG home delivery', True, (850, 950)),
        ('iCloud / Google Cloud Storage', '2TB unified encrypted cloud backup subscription', True, (650, 650)),
    ],
    'Health': [
        ('Apollo Pharmacy Prescription', 'Prescription medication, vitamin D3 & omega-3', True, (450, 1800)),
        ('Dental Scaling & Oral Checkup', 'Bi-annual preventive dental cleaning and exam', True, (1200, 2500)),
        ('Cult.fit Fitness Gym Pass', 'Quarterly fitness center gym and yoga pass', True, (4500, 9500)),
        ('Diagnostic Comprehensive Blood Panel', 'Full body health checkup, liver and lipid profile', True, (2200, 4500)),
        ('Physiotherapy Posture Rehab', 'Spine and cervical posture rehab therapy session', True, (800, 1500)),
        ('Optometry Eye Checkup & Frames', 'Blue-light blocking high-index prescription lenses', True, (2400, 6500)),
    ],
    'Learn': [
        ('Kindle Technical E-Books', 'Software engineering architecture & financial books', True, (450, 1200)),
        ('Udemy Masterclass Bootcamp', 'Full-stack distributed cloud architecture video course', True, (699, 1499)),
        ('Coursera AI Specialization', 'Machine learning and deep neural networks lab', True, (3999, 4999)),
        ('Language Mastery Application', 'Annual conversational language learning subscription', False, (1999, 2999)),
        ('Tech Conference Full Pass', 'Annual developer engineering summit registration', True, (4500, 9500)),
    ],
    'Other': [
        ('Dry Cleaning & Garment Care', 'Winter wool coats, formal suits and blazers clean', True, (600, 1800)),
        ('Deep Home Sanitization Service', 'Quarterly professional deep house cleaning and scrub', True, (2500, 4500)),
        ('Express International Courier', 'Expedited legal document international courier parcel', True, (350, 1200)),
        ('Charity Foundation Contribution', 'Monthly child education and midday meal sponsorship', False, (1000, 5000)),
        ('Friend Wedding / Birthday Gift', 'Custom engraved stainless steel wristwatch with box', False, (2500, 7500)),
    ]
}

start_date = datetime(2025, 1, 1)
end_date = datetime(2026, 8, 22)

rows = ['id,title,category,amount,date,isEssential,note']
tx_id = 1

random.seed(42)  # Deterministic realistic simulation
current_date = start_date

while current_date <= end_date:
    # 2 to 6 transactions per day
    daily_count = random.randint(2, 6)
    for _ in range(daily_count):
        cat = random.choice(list(categories.keys()))
        item = random.choice(categories[cat])
        title, note_template, is_essential, (min_amt, max_amt) = item
        
        if min_amt == max_amt:
            amount = float(min_amt)
        else:
            amount = round(random.uniform(min_amt, max_amt), 2)
            
        date_str = current_date.strftime('%Y-%m-%d')
        note = f"{note_template} (Recorded on {date_str})"
        
        # Clean escape
        note_clean = note.replace(',', ';')
        title_clean = title.replace(',', ';')
        
        rows.append(f"{tx_id},{title_clean},{cat},{amount:.2f},{date_str},{str(is_essential).lower()},{note_clean}")
        tx_id += 1
        
    current_date += timedelta(days=1)

content = '\n'.join(rows)

# Save both files
with open('c:/Projects/Expense_Tracker/sample_transactions_stress_test.csv', 'w', encoding='utf-8') as f:
    f.write(content)

with open('c:/Projects/Expense_Tracker/sample_transactions_1year.csv', 'w', encoding='utf-8') as f:
    f.write(content)

print(f"SUCCESS: Generated {len(rows)-1} rich transactions spanning {start_date.strftime('%b %Y')} to {end_date.strftime('%b %Y')}!")
