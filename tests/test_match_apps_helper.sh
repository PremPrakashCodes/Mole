#!/bin/bash
# Test helper: match_apps_by_name extracted from bin/uninstall.sh for unit testing.
# Requires apps_data and selected_apps arrays to be defined before sourcing.
# NOTE: Keep in sync with bin/uninstall.sh match_apps_by_name()

# Declared by caller before sourcing this file
: "${apps_data?apps_data array must be set before sourcing this file}"

match_apps_by_name() {
    local -a search_terms=("$@")
    selected_apps=()
    local -a matched_indices=()

    for search_term in "${search_terms[@]}"; do
        local search_lower
        search_lower=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')
        # Escape glob characters to prevent pattern injection
        search_lower=${search_lower//\\/\\\\}
        search_lower=${search_lower//\*/\\*}
        search_lower=${search_lower//\?/\\?}
        search_lower=${search_lower//\[/\\[}
        local found=false
        local idx=0
        for app_data in "${apps_data[@]}"; do
            IFS='|' read -r epoch app_path app_name bundle_id size last_used size_kb <<< "$app_data"
            local name_lower
            name_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
            local dir_name
            dir_name=$(basename "$app_path" .app)
            local dir_lower
            dir_lower=$(echo "$dir_name" | tr '[:upper:]' '[:lower:]')

            if [[ "$name_lower" == "$search_lower" || "$dir_lower" == "$search_lower" ]]; then
                local already=false
                local mi
                for mi in "${matched_indices[@]+"${matched_indices[@]}"}"; do
                    [[ -z "$mi" ]] && continue
                    [[ "$mi" == "$idx" ]] && already=true && break
                done
                if [[ "$already" == "false" ]]; then
                    selected_apps+=("$app_data")
                    matched_indices+=("$idx")
                fi
                found=true
                break
            fi
            idx=$((idx + 1))
        done

        # If no exact match, try substring match
        if [[ "$found" == "false" ]]; then
            idx=0
            for app_data in "${apps_data[@]}"; do
                IFS='|' read -r epoch app_path app_name bundle_id size last_used size_kb <<< "$app_data"
                local name_lower
                name_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
                local dir_name
                dir_name=$(basename "$app_path" .app)
                local dir_lower
                dir_lower=$(echo "$dir_name" | tr '[:upper:]' '[:lower:]')

                if [[ "$name_lower" == *"$search_lower"* || "$dir_lower" == *"$search_lower"* ]]; then
                    local already=false
                    local mi
                    for mi in "${matched_indices[@]+"${matched_indices[@]}"}"; do
                        [[ -z "$mi" ]] && continue
                        [[ "$mi" == "$idx" ]] && already=true && break
                    done
                    if [[ "$already" == "false" ]]; then
                        selected_apps+=("$app_data")
                        matched_indices+=("$idx")
                    fi
                    found=true
                fi
                idx=$((idx + 1))
            done
        fi

        if [[ "$found" == "false" ]]; then
            echo "Warning: No application found matching '$search_term'"
        fi
    done
}
