require('dotenv').config();
const prisma = require('../prisma');

async function main() {
  console.log('Seeding Phil-IRI English reading materials (Grades 4-6)...');

  const materials = [
    // GRADE 4 (from Phil-IRI English Grade 4, page 58)
    {
      title: 'The Best Part of the Day',
      gradeLevel: 4,
      passage:
        'Mia was in her bedroom when she heard a rooster crow. Then she heard a man yell, "Hot pandesal! Buy your hot pandesal!" Mia wanted to sleep some more. But she knew she might be late for school if she did. Finally, she began to smell fried eggs and fish. "It\'s time to get up," she said. Mia jumped out of bed and ran down the steps.',
      materialType: 'BUILT_IN',
      questions: [
        {
          questionOrder: 1,
          questionText: 'At the beginning of the story, where was Mia?',
          choiceA: 'She was in her bedroom.',
          choiceB: 'She was in the bathroom.',
          choiceC: 'She was at the kitchen table.',
          choiceD: 'She was on a bench outside.',
          correctAnswer: 'A'
        },
        {
          questionOrder: 2,
          questionText: 'What time of the day was it?',
          choiceA: 'middle of the day',
          choiceB: 'late in the evening',
          choiceC: 'early in the morning',
          choiceD: 'late in the afternoon',
          correctAnswer: 'C'
        },
        {
          questionOrder: 3,
          questionText: 'What do you think will happen next?',
          choiceA: 'She will have lunch.',
          choiceB: 'She will have dinner.',
          choiceC: 'She will have a snack.',
          choiceD: 'She will have breakfast.',
          correctAnswer: 'D'
        },
        {
          questionOrder: 4,
          questionText: 'What will she say when she gets up?',
          choiceA: '"Good evening."',
          choiceB: '"Good afternoon!"',
          choiceC: '"Good morning!"',
          choiceD: '"Thank you very much!"',
          correctAnswer: 'C'
        },
        {
          questionOrder: 5,
          questionText: 'What other title can be given for this story?',
          choiceA: 'The End of the Day',
          choiceB: 'The Start of the Day',
          choiceC: 'Just Before Sleeping',
          choiceD: 'The Middle of the Day',
          correctAnswer: 'B'
        }
      ]
    },

    // GRADE 5 (from Phil-IRI English Grade 5, page 62)
    {
      title: 'Early Start',
      gradeLevel: 5,
      passage:
        'Mara woke up with a start. "Oh no!" The sun was shining brightly on her face. She looked at her alarm clock. She was not going to make it to school. She hurriedly put on her uniform, gathered her things and dumped them into her bag. She rushed so that she could be in school before the bell rang. As she was going out the door, her mother stopped her and asked, "Why are you rushing? Did you forget? It\'s Saturday today!"',
      materialType: 'BUILT_IN',
      questions: [
        {
          questionOrder: 1,
          questionText: 'Mara woke up with a start. When a person wakes up with a start, it means that one got out of bed:',
          choiceA: 'sad',
          choiceB: 'happy',
          choiceC: 'worried',
          choiceD: 'excited',
          correctAnswer: 'C'
        },
        {
          questionOrder: 2,
          questionText: 'Why does Mara have to rush?',
          choiceA: 'so she would get to school on time',
          choiceB: 'so she would be the first student in school',
          choiceC: 'so she would be the fastest runner in school',
          choiceD: 'so she could eat breakfast before going to school',
          correctAnswer: 'A'
        },
        {
          questionOrder: 3,
          questionText: 'What did Mara forget?',
          choiceA: 'that she did not set her alarm clock early enough',
          choiceB: 'that she did not need to rush because there were no classes today',
          choiceC: 'that she cannot anymore eat breakfast',
          choiceD: 'that she cannot anymore go to school',
          correctAnswer: 'B'
        },
        {
          questionOrder: 4,
          questionText: 'How do you think did Mara feel after her mother talked to her?',
          choiceA: 'anxious',
          choiceB: 'nervous',
          choiceC: 'relieved',
          choiceD: 'unhappy',
          correctAnswer: 'C'
        },
        {
          questionOrder: 5,
          questionText: 'What did the author intend when she wrote the selection?',
          choiceA: 'to inform',
          choiceB: 'to entertain',
          choiceC: 'to evaluate',
          choiceD: 'to convince',
          correctAnswer: 'B'
        }
      ]
    },

    // GRADE 6 (from Phil-IRI English Grade 6, page 66)
    {
      title: 'Chameleons',
      gradeLevel: 6,
      passage:
        'Chameleons are extraordinary animals. They are one of the few animals that can change their color. This is their way of hiding themselves. Chameleons that live in trees are often green. Those that live in desert lands are usually brown. It is also their way of keeping warm. Turning a darker shade helps them absorb more heat. They also change colors to send messages to other chameleons. Their bright colors may attract another chameleon or warn enemies.',
      materialType: 'BUILT_IN',
      questions: [
        {
          questionOrder: 1,
          questionText: 'What is one unique characteristic of chameleons?',
          choiceA: 'Their color changes.',
          choiceB: 'They live in trees.',
          choiceC: 'They live in deserts.',
          choiceD: 'They climb trees fast.',
          correctAnswer: 'A'
        },
        {
          questionOrder: 2,
          questionText: 'What will happen to a chameleon on a cold day?',
          choiceA: 'It will become invisible.',
          choiceB: 'It will turn a shade lighter.',
          choiceC: 'It will turn white.',
          choiceD: 'It will turn a shade darker.',
          correctAnswer: 'D'
        },
        {
          questionOrder: 3,
          questionText: "Changing its color is the chameleon's way of:",
          choiceA: 'showing its special power',
          choiceB: 'hiding itself from other animals',
          choiceC: 'finding its family',
          choiceD: 'shedding its skin',
          correctAnswer: 'B'
        },
        {
          questionOrder: 4,
          questionText: 'Chameleons are extraordinary animals. Another word for extraordinary is:',
          choiceA: 'amazing',
          choiceB: 'not known',
          choiceC: 'common',
          choiceD: 'unusual',
          correctAnswer: 'A'
        },
        {
          questionOrder: 5,
          questionText: 'What is the advantage of changing color?',
          choiceA: 'It can hide itself.',
          choiceB: 'It can kill enemies.',
          choiceC: 'It can join with other chameleons.',
          choiceD: 'It can hold on to the branch as it climbs.',
          correctAnswer: 'A'
        }
      ]
    }
  ];

  for (const mat of materials) {
    const existing = await prisma.readingMaterial.findFirst({
      where: { title: mat.title, materialType: 'BUILT_IN' }
    });

    if (!existing) {
      await prisma.readingMaterial.create({
        data: {
          title: mat.title,
          passage: mat.passage,
          gradeLevel: mat.gradeLevel,
          materialType: mat.materialType,
          questions: {
            create: mat.questions
          }
        }
      });
      console.log(`✓ Seeded Grade ${mat.gradeLevel} material: "${mat.title}" with 5 questions.`);
    } else {
      await prisma.readingMaterial.update({
        where: { id: existing.id },
        data: { gradeLevel: mat.gradeLevel }
      });
      console.log(`✓ Updated Grade ${mat.gradeLevel} on existing material "${mat.title}".`);
    }
  }

  console.log('✓ Seeding complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });