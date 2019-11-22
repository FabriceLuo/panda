#! /bin/bash
#
# merge.sh
# Copyright (C) 2019 luominghao <luominghao@live.com>
#
# Distributed under terms of the MIT license.
#

GITLAB_TOKEN="oB-QgDLotz7vo9HxuDgp"
GITLAB_BASE_URL="https://gitlab.com/api/v4"
GITLAB_AUTHOR_ID="4821787"

list_merges()
{
    local project_id=$1
    local merge_status=$2
    local merges=

    merges=$(curl -s "${GITLAB_BASE_URL}/projects/${project_id}/merge_requests?private_token=${GITLAB_TOKEN}&author_id=${GITLAB_AUTHOR_ID}&order_by=updated_at&state=${merge_status}" | jq -r '.[].iid |=tostring | .[] | .iid + " " + .title')
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge list(${merge_status}) failed"
        return 1
    fi

    echo "${merges}"
    return 0
}

get_merge()
{
    local project_id=$1
    local merge_id=$2
    local merge

    merge=$(curl -s "${GITLAB_BASE_URL}/projects/${project_id}/merge_requests/${merge_id}?private_token=${GITLAB_TOKEN}")
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge(${merge_id}) failed"
        return 1
    fi

    echo "${merge}"
    return 0
}

create_merge() {
    local project_id=$1
    local src_branch=$2
    local des_branch=$3
    local merge_title=$4
    local merge_desc=$5
    local assignee_id=$6
    local merge_info

    merge_info=$(curl -s -X POST -H "Content-type: application/x-www-form-urlencoded, charset: utf-8" -d "private_token=${GITLAB_TOKEN}&source_branch=${src_branch}&target_branch=${des_branch}&title=${merge_title}&description=${merge_desc}&assignee_id=${assignee_id}" "${GITLAB_BASE_URL}/projects/${project_id}/merge_requests")
    if [[ $? -ne 0 ]]; then
        echo "create merge request failed"
        return 1
    fi

    echo "${merge_info}"
    return 0
}

update_merge() {
    local project_id=$1
    local merge_id=$2
    local des_branch=$3
    local merge_title=$4
    local merge_desc=$5
    local assignee_id=$6
    local merge_info

    return 0
}

close_merge() {
    local project_id=$1
    local merge_id=$2

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

    project_id=$(echo "${projects}" | jq "foreach .[] as \$item (null;if \$item.ssh_url_to_repo  == \"${project_url}\" then null else empty end; if \$item != null then \$item else empty end) | .id")
    if [[ $? -ne 0 || -z $project_id ]]; then
        echo "get project(${project_name}) id from projects(${projects}) failed"
        return 1
    fi

    echo "${project_id}"
    return 0
}

get_review_persons_count()
{
    curl -s -I -H "Private-Token:${GITLAB_TOKEN}" "${GITLAB_BASE_URL}/api/v4/users" | grep "X-Total:" | awk '{print $2}' | sed 's/\s*//g'
}

list_review_persons()
{
    # 用户列表被分页，多次获取
    local per_page=100
    local page_total=0
    local page_index=1
    local persons_total=0
    local persons_all=
    local persons_page=

    persons_total=$(get_review_persons_count)
    if [[ $? -ne 0 ]]; then
        echo "get review persons total count failed"
        return 1
    fi

    total_pages=$(echo "($persons_total + $per_page - 1) / $per_page" | bc)
    if [[ $? -ne 0 ]]; then
        echo "compute user total pages failed"
        return 1
    fi

    while [[ $page_index -le $total_pages ]]; do
        # 获取页的用户
        persons_page=$(curl -s -H "Private-Token:${GITLAB_TOKEN}" "${GITLAB_BASE_URL}/api/v4/users?page=${page_index}&per_page=${per_page}")
        if [[ $? -ne 0 ]]; then
            echo "get page(${page_index}) users failed"
            return 1
        fi

        if [[ -n $persons_all ]]; then
            # 合入到总的列表中，将persons_all的]换成逗号，将persons_page的[去掉，然后进行字符串合并即可
            persons_all=$(echo "${persons_all}" | sed 's/\]/,/g')
            if [[ $? -ne 0 ]]; then
                echo "update persons_all failed"
                return 1
            fi
            persons_page=$(echo "${persons_page}" | sed 's/\[//')
            if [[ $? -ne 0 ]]; then
                echo "update persons_page failed"
                return 1
            fi
        fi

        persons_all="${persons_all}${persons_page}"
        page_index=$((page_index + 1))
    done

    echo "${persons_all}"
    return 0
}
