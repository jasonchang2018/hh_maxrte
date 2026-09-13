create or replace procedure
    edwprodhh.pub_jchang.insert_maxrte_log()
returns     boolean
language    sql
as
begin

    insert into
        edwprodhh.insurance_discovery.maxrte_request_log
        (
            PACKET_IDX,
            CLIENT_FACILITY,
            CLIENT,
            DEBTOR_ACCOUNT_NUMBER,
            PATIENT_FIRST_NAME,
            PATIENT_LAST_NAME,
            PATIENT_DOB,
            PATIENT_SEX,
            PATIENT_SSN_CUBS,
            PATIENT_SSN_LAT,
            PATIENT_ADDRESS,
            CITY,
            STATE,
            ZIP_CODE,
            GUARANTOR_FIRST_NAME,
            GUARANTOR_LAST_NAME,
            GUARANTOR_SSN_CUBS,
            GUARANTOR_SSN_LAT,
            AMOUNT_DUE,
            CURRENT_BALANCE,
            ADMIT_DATE,
            DISCHARGE_DATE,
            NPI,
            REQUEST_ID,
            DEBT_TYPE,
            PL_GROUP,
            DEBTOR_IDX,
            UPLOAD_DATE,
            CLIENT_MINIMUM,
            DEBTOR_PRIORITY,
            CLIENT_PRIORITY,
            GLOBAL_PRIORITY
        )
    select      packet_idx,
                client_facility,
                client,
                debtor_account_number,
                patient_first_name,
                patient_last_name,
                patient_dob,
                patient_sex,
                patient_ssn_cubs,
                patient_ssn_lat,
                patient_address,
                city,
                state,
                zip_code,
                guarantor_first_name,
                guarantor_last_name,
                guarantor_ssn_cubs,
                guarantor_ssn_lat,
                amount_due,
                current_balance,
                admit_date,
                discharge_date,
                npi,
                request_id,
                debt_type,
                pl_group,
                debtor_idx,
                upload_date,
                client_minimum,
                debtor_priority,
                client_priority,
                global_priority
    from        edwprodhh.insurance_discovery.maxrte_request
    ;

end
;



create or replace task
    edwprodhh.pub_jchang.sp_insert_maxrte_log
    warehouse = analysis_wh
    schedule = 'USING CRON 0 2 * * MON-FRI America/Chicago'
as
call    edwprodhh.pub_jchang.insert_maxrte_log()
;