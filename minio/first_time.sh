#!/bin/bash
# source ../.env

initialize() {
    echo
    echo "Creating alias dtminio"
    # mc alias rm dtminio
    mc alias set dtminio/ http://127.0.0.1:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

    echo
    echo "Configuring region: ${MINIO_REGION}"
    mc admin config set dtminio/ region name=${MINIO_REGION}

    echo
    echo "Restarting server"
    mc admin service restart dtminio/

    echo
    echo "Waitng for server to restart..."
    mc ping dtminio -x --no-color

    echo
    echo "Creating bucket ${MINIO_BUCKET_NAME}"
    mc mb dtminio/${MINIO_BUCKET_NAME} --region "${MINIO_REGION}"

    echo
    echo "Creating access key."
    key_output=$(mc admin accesskey create dtminio)

    # ACCESS_KEY=$(awk -F 'Access Key: ' '{print $2}' <<<"$key_output" | awk '{print $1}' | tr -d '\r\n')
    # SECRET_KEY=$(awk -F 'Secret Key: ' '{print $2}' <<<"$key_output" | awk '{print $1}' | tr -d '\r\n')

    # Parse Access Key and Secret Key
    while IFS= read -r line; do
        case "$line" in
            *"Access Key:"*) ACCESS_KEY=${line#*Access Key: } ; ACCESS_KEY=${ACCESS_KEY%%[[:space:]]*} ;;
            *"Secret Key:"*) SECRET_KEY=${line#*Secret Key: } ; SECRET_KEY=${SECRET_KEY%%[[:space:]]*} ;;
        esac
    done <<< "$key_output"
    ACCESS_KEY=${ACCESS_KEY//$'\r'/}
    SECRET_KEY=${SECRET_KEY//$'\r'/}

    echo
    echo "Finished setting up minio"
    echo
    echo "Configure DT Storage module with the following settings:"
    echo "Provider:             MinIO"
    echo "AccessKey:            $ACCESS_KEY"
    echo "Secret:               $SECRET_KEY"
    echo "Region:               ${MINIO_REGION}"
    echo "Bucket:               ${MINIO_BUCKET_NAME}"
    echo "Endpoint:             https://${MINIO_PUBLIC_DOMAIN}:9000"
    echo "Path-style endpoint:  Checked"
}

if [ "$1" = "deploy" ]; then
    docker cp $0 minio:/first_time.sh
    docker exec -it minio bash /first_time.sh
else
    echo "Running first-time script. To deploy, use: $0 deploy"
    initialize
fi
