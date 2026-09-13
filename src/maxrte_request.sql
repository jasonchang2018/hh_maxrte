create or replace view
    edwprodhh.insurance_discovery.maxrte_request
as
with eligible_clients as
(
    select  'BAYLOR SCOTT WHITE HEALTHCARE EPIC - 3P'   as pl_group,    100     as minimum  union all
    select  'BAYLOR SCOTT WHITE HEALTHCARE EPIC - 3P-2' as pl_group,    100     as minimum  union all
    select  'BROWARD HEALTH - 3P'                       as pl_group,    50      as minimum  union all
    select  'CARLE HEALTHCARE - 3P'                     as pl_group,    100     as minimum  union all
    select  'CARLE HEALTHCARE - 3P-2'                   as pl_group,    50      as minimum  union all
    select  'CHOP - 3P'                                 as pl_group,    50      as minimum  union all
    select  'COLUMBIA DOCTORS - 3P'                     as pl_group,    0       as minimum  union all
    select  'FRANCISCAN HEALTH - 3P'                    as pl_group,    0       as minimum  union all
    select  'MD ANDERSON - 3P'                          as pl_group,    0       as minimum  union all
    select  'MOUNT SINAI - 3P'                          as pl_group,    0       as minimum  union all
    select  'NORTHSHORE UNIV HEALTH - 3P'               as pl_group,    200     as minimum  union all
    select  'NORTHWESTERN MEDICINE - 3P'                as pl_group,    0       as minimum  union all
    select  'NW COMM HOSP - 3P'                         as pl_group,    100     as minimum  union all
    select  'NW COMM HOSP - 3P-2'                       as pl_group,    0       as minimum  union all
    -- select  'PRISMA HEALTH - 3P'                        as pl_group,    200     as minimum  union all
    -- select  'PRISMA HEALTH - 3P-2'                      as pl_group,    0       as minimum  union all
    select  'PROMEDICA HS - 3P-2'                       as pl_group,    0       as minimum  union all
    select  'UNIVERSAL HEALTH SERVICES - 3P'            as pl_group,    800     as minimum  union all
    select  'UNIVERSAL HEALTH SERVICES - PHYS - 3P'     as pl_group,    300     as minimum  union all
    select  'WEILL CORNELL PHY - 3P'                    as pl_group,    0       as minimum
)
, npi_latitude as
(
    select      mapping.client_idx_lat,
                nullif(trim(dimclient.npi_number), '') as npi
    from        edwprodhh.pub_jchang.map_cubs_client as mapping
                inner join
                    edwprodhh.dw.dimclient as dimclient
                    on mapping.client_idx_cubs = dimclient.client_idx
    where       mapping.client_idx_lat is not null
                and npi is not null
    qualify     row_number() over (partition by mapping.client_idx_lat order by npi asc) = 1
)
, filtered as
(
    select      debtor.packet_idx                                                                                                               as packet_idx,
                client.name                                                                                                                     as client_facility,
                debtor.client                                                                                                                   as client,
                debtor.debtornumber                                                                                                             as debtor_account_number,

                coalesce(nullif(trim(patientinfo.name), ''), nullif(trim(dimfiscal_hh_b.patient_name), ''))                                     as rawname_patient,

                case    when    regexp_like(rawname_patient, '.*\\,.*')
                        then    nullif(trim(regexp_substr(rawname_patient, '^([^,]*)', 1, 1, 'e')), '')
                        else    nullif(trim(regexp_substr(rawname_patient, '(([^\\s]*)([\\,\\s]+(JR|SR|I+)\\.?)?)$', 1, 1, 'e')), '')
                        end                                                                                                                     as lastname_patient,

                case    when    regexp_like(rawname_patient, '.**\\,.*')
                        then    nullif(trim(regexp_replace(replace(rawname_patient, lastname_patient, ''), '^\\s*\\,\\s*')), '')
                        else    nullif(trim(replace(rawname_patient, lastname_patient, '')), '')
                        end                                                                                                                     as non_lastname_patient,

                case    when    regexp_like(non_lastname_patient, '.*\\s.*')
                        then    regexp_substr(non_lastname_patient, '([^\\s]*)$', 1, 1, 'e')
                        end                                                                                                                     as middlename_patient,

                case    when    regexp_like(non_lastname_patient, '.*\\s.*')
                        then    nullif(trim(left(non_lastname_patient, length(non_lastname_patient) - length(middlename_patient))), '')
                        else    non_lastname_patient
                        end                                                                                                                     as firstname_patient,


                coalesce(patientinfo.dob, dimfiscal_hh_b.patient_dob)                                                                           as patient_dob,
                coalesce(nullif(trim(patientinfo.sex), ''), nullif(trim(dimfiscal_hh_b.patient_sex), ''))                                       as patient_sex,
                dimfiscal_hh_b.patient_ssn                                                                                                      as patient_ssn_cubs,
                patientinfo.ssn                                                                                                                 as patient_ssn_lat,
                coalesce(patientinfo.street1, dimfiscal_hh_b.patient_address)                                                                   as patient_address_,
                debtor.city                                                                                                                     as city,
                debtor.state                                                                                                                    as state,
                debtor.zip_code                                                                                                                 as zip_code,

                coalesce(nullif(trim(dimfiscal_hh_d.guar_name_f946), ''), nullif(trim(debtor.fullname), ''))                                    as rawname_guarantor,



                case    when    regexp_like(rawname_guarantor, '.*\\,.*')
                        then    nullif(trim(regexp_substr(rawname_guarantor, '^([^,]*)', 1, 1, 'e')), '')
                        else    nullif(trim(regexp_substr(rawname_guarantor, '(([^\\s]*)([\\,\\s]+(JR|SR|I+)\\.?)?)$', 1, 1, 'e')), '')
                        end                                                                                                                     as lastname_guarantor,

                case    when    regexp_like(rawname_guarantor, '.**\\,.*')
                        then    nullif(trim(regexp_replace(replace(rawname_guarantor, lastname_guarantor, ''), '^\\s*\\,\\s*')), '')
                        else    nullif(trim(replace(rawname_guarantor, lastname_guarantor, '')), '')
                        end                                                                                                                     as non_lastname_guarantor,

                case    when    regexp_like(non_lastname_guarantor, '.*\\s.*')
                        then    regexp_substr(non_lastname_guarantor, '([^\\s]*)$', 1, 1, 'e')
                        end                                                                                                                     as middlename_guarantor,

                case    when    regexp_like(non_lastname_guarantor, '.*\\s.*')
                        then    nullif(trim(left(non_lastname_guarantor, length(non_lastname_guarantor) - length(middlename_guarantor))), '')
                        else    non_lastname_guarantor
                        end                                                                                                                     as firstname_guarantor,

                dimfiscal_hh_d.guar_ssn_f947                                                                                                    as guarantor_ssn_cubs,
                master.ssn                                                                                                                      as guarantor_ssn_lat,
                debtor.assigned                                                                                                                 as amount_due,
                debtor.balance_dimdebtor                                                                                                        as current_balance,
                coalesce(patientinfo.admissiondate, dimfiscal_hh_b.admit_date)                                                                  as admit_date_,
                coalesce(patientinfo.dischargedate, dimfiscal_hh_b.discharge_date, dimfiscal_hh_b.admit_date)                                   as discharge_date,
                coalesce(npi_latitude.npi, dimclient.npi_number)                                                                                as npi,
                randstr(16, random())                                                                                                           as request_id,
                client.debt_type                                                                                                                as debt_type,           --not sent to vendor
                debtor.pl_group                                                                                                                 as pl_group,            --not sent to vendor
                eligible_clients.minimum                                                                                                        as client_minimum,      --not sent to vendor
                row_number() over (order by     case    when    debtor.debt_type = 'SP'
                                                        then    3
                                                        when    debtor.debt_type = 'AI'
                                                        then    2
                                                        else    1
                                                        end         desc,
                                                debtor.batch_date   desc,
                                                debtor.debtor_idx   desc)                                                                       as debtor_priority,     --not sent to vendor
                debtor.debtor_idx                                                                                                               as debtor_idx,          --not sent to vendor
                current_date()                                                                                                                  as upload_date          --not sent to vendor
    from        edwprodhh.pub_jchang.master_debtor as debtor
                inner join
                    edwprodhh.pub_jchang.master_client as client
                    on debtor.client_idx = client.client_idx
                inner join
                    eligible_clients
                    on debtor.pl_group = eligible_clients.pl_group

                left join
                    edwprodhh.dw.dimclient as dimclient
                    on client.client_idx = dimclient.client_idx

                left join
                    edwprodhh.liquid.patientinfo as patientinfo
                    on debtor.debtor_idx = 'LAT-' || patientinfo.accountid
                left join
                    edwprodhh.liquid.master as master
                    on debtor.debtor_idx = 'LAT-' || master.number
                left join
                    npi_latitude
                    on debtor.client_idx = npi_latitude.client_idx_lat

                left join
                    edwprodhh.dw.dimfiscal_hh_b as dimfiscal_hh_b
                    on debtor.debtor_idx = dimfiscal_hh_b.debtor_idx
                left join
                    edwprodhh.dw.dimfiscal_hh_d as dimfiscal_hh_d
                    on debtor.debtor_idx = dimfiscal_hh_d.debtor_idx
                left join
                    edwprodhh.dw.dimfiscal_hh_a as dimfiscal_hh_a
                    on debtor.debtor_idx = dimfiscal_hh_a.debtor_idx

                left join
                    (
                        select      distinct
                                    debtor_idx
                        from        edwprodhh.pub_jchang.master_transactions
                        where       is_payment = 1
                    ) as trans
                    on  debtor.debtor_idx = trans.debtor_idx                

    where       datediff(month, admit_date_, current_date()) <= 10
                and debtor.is_active = 1
                and debtor.balance_dimdebtor >= 100
                and debtor.state in (
                    'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL',
                    'GA','HI','ID','IL','IN','IA','KS','KY','LA','ME',
                    'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH',
                    'NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI',
                    'SC','SD','TN','TX','TT','UT','VT','VA','WA','WV',
                    'WI','WY'
                )
                and trans.debtor_idx is null

                and rawname_patient is not null
                and patient_address_ is not null
                and case    when    debtor.system_source = 'CUBS'
                            then    case    when    nullif(trim(dimfiscal_hh_a.ins_name), '') is null
                                            then    TRUE
                                            when    len(trim(dimfiscal_hh_a.ins_name)) < 2
                                            then    TRUE
                                            else    FALSE
                                            end
                            when    debtor.system_source = 'LATITUDE'
                            then    case    when    exists (select 1 from edwprodhh.liquid.insurance as insurance where debtor.debtornumber = insurance.number and nullif(trim(insurance.policynumber), '') is not null)
                                            then    FALSE
                                            else    TRUE
                                            end
                            else    FALSE
                            end
                and debtor.packet_idx not in (  select      packet_idx
                                                from        edwprodhh.insurance_discovery.maxrte_request_log)
                and debtor.packet_idx not in (  select      mapping.packet_idx_lat
                                                from        edwprodhh.insurance_discovery.maxrte_request_log as logger
                                                            inner join
                                                                edwprodhh.pub_jchang.map_cubs_debtor as mapping
                                                                on logger.packet_idx = mapping.packet_idx_cubs)
                and debtor.debt_type = 'SP'
)
, filter_best_packet_option as
(
    select      *
    from        filtered
    qualify     row_number() over ( partition by    pl_group,
                                                    packet_idx
                                    order by        debtor_priority asc) = 1
)
, calculate_global_priority as
(
    select      *,

                row_number() over ( partition by    pl_group
                                    order by        debtor_priority asc)                                                                as client_priority,             --not sent to vendor

                row_number() over ( order by        case    when    pl_group in ('UNIVERSAL HEALTH SERVICES - PHYS - 3P')
                                                            then    1
                                                            else    0
                                                            end     desc,
                                                    debtor_priority asc)                                                                as global_priority,            --not sent to vendor
    from        filter_best_packet_option
)
select		packet_idx,
            client_facility,
            client,
            debtor_account_number,
            firstname_patient as patient_first_name,
            lastname_patient as patient_last_name,
            patient_dob,
            patient_sex,
            -- patient_ssn,
            patient_ssn_cubs,
            patient_ssn_lat,
            patient_address_ as patient_address,
            city,
            state,
            zip_code,
            firstname_guarantor as guarantor_first_name,
            lastname_guarantor as guarantor_last_name,
            -- guarantor_ssn,
            guarantor_ssn_cubs,
            guarantor_ssn_lat,
            amount_due,
            current_balance,
            admit_date_ as admit_date,
            discharge_date,
            npi,
            request_id,
            debt_type,
            pl_group,
            client_minimum,
            debtor_priority,
            debtor_idx,
            upload_date,
            client_priority,
            global_priority
from		calculate_global_priority
qualify     row_number() over (order by     case    when    client_priority <= client_minimum
                                                    then    1
                                                    else    0
                                                    end     desc,
                                            global_priority asc)    <= 2500
;