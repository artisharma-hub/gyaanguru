"""
Seed the database with sample questions.
Run: python seed_questions.py
(Make sure .env is set up and the DB is running.)
"""
import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from app.database import AsyncSessionLocal, init_db
from app.models.question import Question

QUESTIONS = [
    # ── Cricket ──────────────────────────────────────────────────────────────
    ("Which team won IPL 2023?", "Mumbai Indians", "CSK", "GT", "RCB", "B", "cricket", "medium"),
    ("Who scored 100 international centuries?", "Rahul Dravid", "Virat Kohli", "Sachin Tendulkar", "Sourav Ganguly", "C", "cricket", "easy"),
    ("India won its first Cricket World Cup in which year?", "1975", "1979", "1983", "1987", "C", "cricket", "medium"),
    ("Which country hosts The Ashes?", "India", "Australia", "England", "South Africa", "C", "cricket", "easy"),
    ("Who is known as 'The Wall' in cricket?", "MS Dhoni", "Rahul Dravid", "VVS Laxman", "Anil Kumble", "B", "cricket", "easy"),
    ("IPL stands for?", "Indian Premier League", "International Premier League", "Indian Power League", "Inter-state Premier League", "A", "cricket", "easy"),
    ("Which IPL team plays at Wankhede Stadium?", "CSK", "RCB", "Mumbai Indians", "KKR", "C", "cricket", "easy"),
    ("Jasprit Bumrah plays for which IPL team?", "CSK", "RCB", "Mumbai Indians", "KKR", "C", "cricket", "easy"),
    ("Which bowler has taken the most Test wickets for India?", "Zaheer Khan", "Anil Kumble", "Kapil Dev", "Ishant Sharma", "B", "cricket", "medium"),
    ("The Duckworth-Lewis method is used in which sport?", "Football", "Hockey", "Cricket", "Tennis", "C", "cricket", "medium"),

    # ── Bollywood ────────────────────────────────────────────────────────────
    ("Who directed 'Dangal'?", "Nitesh Tiwari", "Karan Johar", "Rajkumar Hirani", "Zoya Akhtar", "A", "bollywood", "easy"),
    ("Who directed '3 Idiots'?", "Karan Johar", "Rajkumar Hirani", "Zoya Akhtar", "Anurag Kashyap", "B", "bollywood", "easy"),
    ("'Jai Ho' was the original title of which film?", "Slumdog Millionaire", "3 Idiots", "Dhoom", "Sholay", "A", "bollywood", "medium"),
    ("Which 2023 film starred Shah Rukh Khan as a spy?", "Pathaan", "Jawan", "Dunki", "Tiger 3", "A", "bollywood", "easy"),
    ("'Baazigar' starred which actor in a double role?", "Aamir Khan", "Shah Rukh Khan", "Salman Khan", "Akshay Kumar", "B", "bollywood", "medium"),
    ("Which film features the song 'Chaiyya Chaiyya'?", "DDLJ", "Dil Se", "Kuch Kuch Hota Hai", "Lagaan", "B", "bollywood", "medium"),
    ("AR Rahman composed the music for which Oscar-winning film?", "Lagaan", "Slumdog Millionaire", "Water", "Monsoon Wedding", "B", "bollywood", "easy"),
    ("Which actress played Paro in Devdas (2002)?", "Aishwarya Rai", "Madhuri Dixit", "Rani Mukerji", "Kajol", "A", "bollywood", "easy"),
    ("'RRR' is directed by?", "Mani Ratnam", "SS Rajamouli", "Shankar", "Trivikram", "B", "bollywood", "easy"),
    ("Which film won India's first National Award for Best Picture?", "Mother India", "Awaara", "Shree 420", "Do Bigha Zamin", "D", "bollywood", "hard"),

    # ── GK ───────────────────────────────────────────────────────────────────
    ("India's first Prime Minister was?", "Sardar Patel", "Dr. Ambedkar", "Jawaharlal Nehru", "Mahatma Gandhi", "C", "gk", "easy"),
    ("National animal of India is?", "Lion", "Elephant", "Tiger", "Leopard", "C", "gk", "easy"),
    ("How many states does India have?", "27", "28", "29", "30", "B", "gk", "easy"),
    ("The Indian constitution was adopted on?", "15 Aug 1947", "26 Jan 1950", "2 Oct 1948", "26 Nov 1949", "B", "gk", "medium"),
    ("Which planet is known as the Red Planet?", "Venus", "Jupiter", "Saturn", "Mars", "D", "gk", "easy"),
    ("The Taj Mahal is located in which city?", "Delhi", "Jaipur", "Agra", "Lucknow", "C", "gk", "easy"),
    ("Who was the first President of India?", "Dr. Rajendra Prasad", "Dr. S. Radhakrishnan", "Jawaharlal Nehru", "Sardar Patel", "A", "gk", "easy"),
    ("India's currency is managed by?", "Finance Ministry", "SEBI", "RBI", "NABARD", "C", "gk", "easy"),
    ("The longest river in India is?", "Ganga", "Yamuna", "Godavari", "Brahmaputra", "A", "gk", "easy"),
    ("How many members are in the Rajya Sabha?", "250", "245", "543", "552", "B", "gk", "medium"),

    # ── Math ─────────────────────────────────────────────────────────────────
    ("What is 15% of 200?", "25", "30", "35", "20", "B", "math", "easy"),
    ("What is 25% of 320?", "60", "70", "80", "90", "C", "math", "easy"),
    ("What is the square root of 144?", "10", "11", "12", "14", "C", "math", "easy"),
    ("What is 18 × 12?", "196", "206", "216", "226", "C", "math", "easy"),
    ("If x + 7 = 15, what is x?", "6", "7", "8", "9", "C", "math", "easy"),
    ("What is 45² ?", "2000", "2025", "2050", "2075", "B", "math", "medium"),
    ("What is the LCM of 4 and 6?", "8", "10", "12", "24", "C", "math", "easy"),
    ("What percentage is 40 of 200?", "15%", "20%", "25%", "30%", "B", "math", "easy"),
    ("What is the value of π (approx)?", "3.14", "3.16", "3.18", "3.12", "A", "math", "easy"),
    ("Solve: 3x - 9 = 0", "x = 2", "x = 3", "x = 4", "x = 5", "B", "math", "easy"),

    # ── Science ──────────────────────────────────────────────────────────────
    ("Which planet is closest to the Sun?", "Venus", "Earth", "Mercury", "Mars", "C", "science", "easy"),
    ("What gas do plants absorb from the atmosphere?", "Oxygen", "Nitrogen", "Carbon Dioxide", "Hydrogen", "C", "science", "easy"),
    ("What is the chemical symbol for Gold?", "Go", "Gd", "Au", "Ag", "C", "science", "easy"),
    ("How many bones are in the adult human body?", "196", "206", "216", "226", "B", "science", "medium"),
    ("What is the powerhouse of the cell?", "Nucleus", "Ribosome", "Mitochondria", "Golgi body", "C", "science", "easy"),
    ("Water is a compound of?", "H and C", "H and O", "O and N", "H and N", "B", "science", "easy"),
    ("The speed of light is approximately?", "3×10⁶ m/s", "3×10⁷ m/s", "3×10⁸ m/s", "3×10⁹ m/s", "C", "science", "medium"),
    ("Which planet has the most moons?", "Jupiter", "Saturn", "Uranus", "Neptune", "B", "science", "medium"),
    ("DNA stands for?", "Deoxyribose Nucleic Acid", "Dioxynucleic Acid", "Deoxyribonucleic Acid", "Dinucleotide Acid", "C", "science", "easy"),
    ("The study of plants is called?", "Zoology", "Botany", "Ecology", "Mycology", "B", "science", "easy"),

    # ── Hindi ────────────────────────────────────────────────────────────────
    ("'Akele chalne wale' — is it a proverb about?", "Loneliness", "Bravery", "Independence", "Freedom", "C", "hindi", "medium"),
    ("'Gharwali' is a word related to?", "House", "Kitchen", "Wife", "Garden", "C", "hindi", "easy"),
    ("'Saahitya' means?", "Literature", "History", "Science", "Music", "A", "hindi", "easy"),
    ("Which suffix makes a verb past tense in Hindi?", "-na", "-ta", "-ya", "-kar", "C", "hindi", "medium"),
    ("'Andha kanoon' is a phrase meaning?", "Blind law", "Broken law", "Silent law", "Hidden law", "A", "hindi", "easy"),
    ("'Parishram' means?", "Patience", "Diligence", "Courage", "Silence", "B", "hindi", "easy"),
    ("'Swabhimaan' means?", "Self-doubt", "Self-respect", "Self-pity", "Self-control", "B", "hindi", "easy"),
    ("Which Devanagari vowel is pronounced 'ee'?", "अ", "आ", "इ", "ई", "D", "hindi", "easy"),
    ("'Vidyalaya' means?", "Library", "Hospital", "School", "Court", "C", "hindi", "easy"),
    ("'Sansar' in Hindi refers to?", "Journey", "Family", "World/Universe", "Dream", "C", "hindi", "medium"),
]


async def seed():
    await init_db()
    async with AsyncSessionLocal() as db:
        for row in QUESTIONS:
            q = Question(
                question_text=row[0],
                option_a=row[1],
                option_b=row[2],
                option_c=row[3],
                option_d=row[4],
                correct_option=row[5],
                category=row[6],
                difficulty=row[7],
            )
            db.add(q)
        await db.commit()
    print(f"Seeded {len(QUESTIONS)} questions.")


if __name__ == "__main__":
    asyncio.run(seed())
