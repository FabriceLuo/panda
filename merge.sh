#! /bin/bash
#
# merge.sh
# Copyright (C) 2019 luominghao <luominghao@live.com>
#
# Distributed under terms of the Sangfor license.
#

GITLAB_TOKEN="FRQ7RnE9uRDonA5EL-iL"
GITLAB_BASE_URL=""
GITLAB_AUTHOR_ID="15"

list_merges()
{
    local project_id=$1
    local merge_status=$2
    local merges=

    merges=$(curl -s "${GITLAB_BASE_URL}/projects/${project_id}/merge_requests?private_token=${GITLAB_TOKEN}&author_id=${GITLAB_AUTHOR_ID}&order_by=updated_at&state=${merge_status}" | jq -r '.[].id |=tostring | .[] | .id + ":" + .title')
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge list(${merge_status}) failed"
        return 1
    fi

    echo "${merges}"
    return 0
}

get_merge() {
    local merge_id=$1
    return 0
}

create_merge() {
    return 0
}

update_merge() {
    return 0
}

close_merge() {
    return 0
}

reopen_merge() {
    return 0
}

get_project_id() {
    local project_name=$1
    local project_url=$2
    local projects=
    local project_id=

    # 搜索project_name，然后对比project_url
    projects=$(curl -s "${GITLAB_BASE_URL}/projects?private_token=${GITLAB_TOKEN}&simple=true&search=${project_name}")
    if [[ $? -ne 0 ]]; then
        echo "search projects with regex(${project_name}) failed"
        return 1
    fi

    project_id=$(echo "${projects}" | foreach .[] as $item (null;if $item.ssh_url_to_repo  == "${project_url}" then null else empty end; if $item != null then $item else empty end) | .id)
    if [[ $? -ne 0 || -z $project_id ]]; then
        echo "get project(${project_name}) id from projects(${projects}) failed"
        return 1
    fi

    echo "${project_id}"
    return 0
}
