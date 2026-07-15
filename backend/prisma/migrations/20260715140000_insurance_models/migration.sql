-- CreateTable
CREATE TABLE "insurance_companies" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "logo_url" TEXT NOT NULL,
    "clinic_id" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "insurance_companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "insurance_coverages" (
    "id" TEXT NOT NULL,
    "insurance_id" TEXT NOT NULL,
    "max_limit" DOUBLE PRECISION NOT NULL,
    "pharmacy_percentage" DOUBLE PRECISION NOT NULL,
    "ambulance_percentage" DOUBLE PRECISION NOT NULL,
    "laboratory_percentage" DOUBLE PRECISION NOT NULL,
    "er_consultation_percentage" DOUBLE PRECISION NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "insurance_coverages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "patient_policies" (
    "id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "insurance_id" TEXT NOT NULL,
    "policy_number" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "patient_policies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medical_invoices" (
    "id" TEXT NOT NULL,
    "request_id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "insurance_id" TEXT NOT NULL,
    "subtotal" DOUBLE PRECISION NOT NULL,
    "covered_amount" DOUBLE PRECISION NOT NULL,
    "copay_amount" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medical_invoices_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "insurance_companies_name_key" ON "insurance_companies"("name");

-- CreateIndex
CREATE UNIQUE INDEX "patient_policies_patient_id_insurance_id_key" ON "patient_policies"("patient_id", "insurance_id");

-- AddForeignKey
ALTER TABLE "insurance_companies" ADD CONSTRAINT "insurance_companies_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "medical_facilities"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "insurance_coverages" ADD CONSTRAINT "insurance_coverages_insurance_id_fkey" FOREIGN KEY ("insurance_id") REFERENCES "insurance_companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_policies" ADD CONSTRAINT "patient_policies_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_policies" ADD CONSTRAINT "patient_policies_insurance_id_fkey" FOREIGN KEY ("insurance_id") REFERENCES "insurance_companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medical_invoices" ADD CONSTRAINT "medical_invoices_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medical_invoices" ADD CONSTRAINT "medical_invoices_insurance_id_fkey" FOREIGN KEY ("insurance_id") REFERENCES "insurance_companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;
