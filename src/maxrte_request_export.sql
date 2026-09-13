create or replace view
    edwprodhh.insurance_discovery.maxrte_request_export
as
select      packet_idx,
            client_facility,
            client,
            debtor_account_number,
            patient_first_name,
            patient_last_name,
            patient_dob,
            patient_sex,
            coalesce(patient_ssn_cubs, patient_ssn_lat)     as  patient_ssn,
            patient_address,
            city,
            state,
            zip_code,
            guarantor_first_name,
            guarantor_last_name,
            coalesce(guarantor_ssn_cubs, guarantor_ssn_lat) as guarantor_ssn,
            amount_due,
            current_balance,
            admit_date,
            discharge_date,
            npi,
            request_id
from        edwprodhh.insurance_discovery.maxrte_request_log
where       upload_date = current_date()
;