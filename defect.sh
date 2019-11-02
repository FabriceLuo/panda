#! /bin/bash

DEFECT_BASE_URL="http://td.sangfor.com/api/v1"
MY_DEFECT_USER_ID="10500"
DEFECT_PRODUCT_ID="10038"
DEFECT_TOKEN_ID="e3758f4c-f3a8-11e9-9a1f-0242ac120007"

DEFECT_REQ_HEADER="-H Content-Type:application/json;charset=UTF-8 -H token:${DEFECT_TOKEN_ID}"

get_defects_search_req_template() {
    local req_data=

    req_data=$(echo "{}" | jq '.query_conditions|={} | .query_conditions.or|={} | .query_conditions.or.fields|={} | .query_conditions.and|={} | .query_conditions.and.fields|={}')
    if [[ $? -ne 0 ]]; then
        echo "construct defect requst template failed"
        return 1
    fi

    echo "${req_data}"
    return 0
}

get_defects() {
    local user_ids=$1
    local defect_statuses=$2
    local req_time=
    local condition=""
    local req_data=

    req_time=$(date +%s)
    if [[ $? -ne 0 ]]; then
        echo "get request time failed"
        return 1
    fi

    req_data=$(get_defects_search_req_template)
    if [[ $? -ne 0 ]]; then
        echo "construct defect requst template failed"
        return 1
    fi
    req_data=$(echo "${req_data}" | jq ".project_id|=\"${DEFECT_PRODUCT_ID}\"")
    if [[ $? -ne 0 ]]; then
        echo "set defect request project id failed"
        return 1
    fi
    req_data=$(echo "${req_data}" | jq ".query_conditions.or.fields.assigner|=[${user_ids}]")
    if [[ $? -ne 0 ]]; then
        echo "set defect request user ids failed"
        return 1
    fi
    req_data=$(echo "${req_data}" | jq ".query_conditions.or.fields.status_tag|=[${defect_statuses}]")
    if [[ $? -ne 0 ]]; then
        echo "set defect request user ids failed"
        return 1
    fi

    defects=$(curl -s -X POST $DEFECT_REQ_HEADER --data "${req_data}" "${DEFECT_BASE_URL}/defect/es/es_search_by_fields?_t=${req_time}")
    if [[ $? -ne 0 ]]; then
        echo "list defects failed, condition:${condition}"
        return 1
    fi

    echo "${defects}" | jq ".data.rows"
    if [[ $? -ne 0 ]]; then
        echo "extract defects failed"
        return 1
    fi
    return 0
}

get_defects_by_user()
{
    local user_id=$1
    local defect_status=$2
    local defects

    defects=$(get_defects "${user_id}" "${defect_status}")
    if [[ $? -ne 0 ]]; then
        echo "list user(${user_id}) status(${defect_status}) defects failed"
        return 1
    fi

    echo "${defects}"
    return 0
}

get_defects_by_me() {
    local defect_status=$1
    local defects=

    defects=$(get_defects_by_user "${MY_DEFECT_USER_ID}" "${defect_status}")
    if [[ $? -ne 0 ]]; then
        echo "list user(${MY_DEFECT_USER_ID}) defects failed"
        return 1
    fi

    echo "${defects}"
    return 0
}

create_defect() {
    return 0
}

fix_defect() {

    return 0
}

reject_defect() {
    return 0
}

update_defect() {
    return 0
}

get_defect_id() {
    return 0
}

get_defect_summary() {
    return 0
}

get_defect_desc() {
    return 0
}

get_defect()
{
    return 0
}
