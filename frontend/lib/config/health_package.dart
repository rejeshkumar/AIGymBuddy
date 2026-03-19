/// Pre-gym health test package - recommended screenings before joining a gym.
class HealthPackage {
  final String id;
  final String name;
  final String description;
  final List<HealthTest> tests;

  const HealthPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.tests,
  });
}

class HealthTest {
  final String id;
  final String name;
  final String category;
  final String description;
  final String? unit;
  final String? normalRange;
  final bool required;

  const HealthTest({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.unit,
    this.normalRange,
    this.required = false,
  });
}

/// Standard pre-gym health package recommended by fitness professionals.
const preGymHealthPackage = HealthPackage(
  id: 'pre_gym_standard',
  name: 'Pre-Gym Health Screening',
  description:
      'Recommended health tests before starting a gym membership. '
      'Consult your doctor for personalized advice.',
  tests: [
    HealthTest(
      id: 'blood_pressure',
      name: 'Blood Pressure',
      category: 'Cardiovascular',
      description: 'Resting blood pressure (systolic/diastolic)',
      unit: 'mmHg',
      normalRange: '120/80 or below',
      required: true,
    ),
    HealthTest(
      id: 'ecg',
      name: 'ECG / EKG',
      category: 'Cardiovascular',
      description: 'Electrocardiogram to check heart rhythm',
      normalRange: 'Normal sinus rhythm',
      required: false,
    ),
    HealthTest(
      id: 'lipid_profile',
      name: 'Lipid Profile',
      category: 'Blood Work',
      description: 'Total cholesterol, LDL, HDL, triglycerides',
      unit: 'mg/dL',
      normalRange: 'Total < 200, LDL < 100, HDL > 40',
      required: true,
    ),
    HealthTest(
      id: 'blood_glucose',
      name: 'Fasting Blood Glucose',
      category: 'Blood Work',
      description: 'Blood sugar level after 8+ hours fasting',
      unit: 'mg/dL',
      normalRange: '70–100',
      required: true,
    ),
    HealthTest(
      id: 'hba1c',
      name: 'HbA1c',
      category: 'Blood Work',
      description: 'Average blood sugar over 2–3 months',
      unit: '%',
      normalRange: 'Below 5.7% (normal), 5.7–6.4% (prediabetes)',
      required: false,
    ),
    HealthTest(
      id: 'cbc',
      name: 'Complete Blood Count (CBC)',
      category: 'Blood Work',
      description: 'Hemoglobin, RBC, WBC, platelets',
      required: false,
    ),
    HealthTest(
      id: 'kidney',
      name: 'Kidney Function',
      category: 'Blood Work',
      description: 'Creatinine, BUN, eGFR',
      unit: 'mg/dL',
      normalRange: 'Creatinine 0.7–1.3 (men), 0.6–1.1 (women)',
      required: false,
    ),
    HealthTest(
      id: 'thyroid',
      name: 'Thyroid (TSH)',
      category: 'Blood Work',
      description: 'Thyroid-stimulating hormone',
      unit: 'mIU/L',
      normalRange: '0.4–4.0',
      required: false,
    ),
    HealthTest(
      id: 'vitamin_d',
      name: 'Vitamin D',
      category: 'Blood Work',
      description: 'Vitamin D level for bone and muscle health',
      unit: 'ng/mL',
      normalRange: '30–50 (sufficient)',
      required: false,
    ),
    HealthTest(
      id: 'bmi',
      name: 'BMI & Body Composition',
      category: 'Physical',
      description: 'Body Mass Index, body fat %, waist circumference',
      normalRange: 'BMI 18.5–24.9 (normal)',
      required: true,
    ),
    HealthTest(
      id: 'basic_fitness',
      name: 'Basic Fitness Assessment',
      category: 'Physical',
      description: 'Resting heart rate, flexibility, strength baseline',
      required: false,
    ),
  ],
);
