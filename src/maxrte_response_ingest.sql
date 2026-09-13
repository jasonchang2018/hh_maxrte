snowsql -q 'put file://C:\\Users\\jchang\\Desktop\\Projects\\incidentals\\2025-04-15-insurance-discovery\\maxrte-response-20250422.csv @edwprodhh.pub_jchang.csv_default_stage;'

copy into
    edwprodhh.insurance_discovery.maxrte_response_log
from
	@edwprodhh.pub_jchang.csv_default_stage/maxrte-response-20250422.csv.gz
	file_format = edwprodhh.pub_jchang.csv_default
;

--manually updated value for FILE_DATE, FILE_NAME
--include these into Jeff's script