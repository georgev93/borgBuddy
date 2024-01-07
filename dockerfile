ARG BASE_IMAGE_VERSION=latest
FROM alpine:$BASE_IMAGE_VERSION

ARG KEY_DIR
ARG BACKUP_TARGET_ADDRESS
ARG BACKUP_TARGET_PORT=22

# Make these env variables so the entry script can grab them
ENV BACKUP_TARGET_ADDRESS=$BACKUP_TARGET_ADDRESS
ENV BACKUP_TARGET_PORT=$BACKUP_TARGET_PORT

# Import custom sshd settings
COPY ./borg-sshdConfig/sshd_config /etc/ssh/sshd_config.d/99-customSshd.conf

# Install software
RUN apk --no-cache add borgbackup py3-packaging openssh sudo

# Set Timezone
RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/America/New_York /etc/localtime \
  && echo "America/New_York" > /etc/timezone \
  && apk del tzdata

# Create and select root account
USER root
WORKDIR /

# Generate hostkeys for the sshd daemon
RUN ssh-keygen -A -N ''

# Create user account
RUN adduser -D borgUser

# Allow password-less sudo
RUN echo 'borgUser ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

# Move imported creds to the .ssh folder
RUN mkdir /home/borgUser/.ssh
RUN chown borgUser /home/borgUser/.ssh
RUN chmod 0700 /home/borgUser/.ssh
COPY $KEY_DIR/* /home/borgUser/.ssh/
RUN chown borgUser /home/borgUser/.ssh/*
RUN chmod 0600 /home/borgUser/.ssh/*

# Import scripts
RUN mkdir /scripts
RUN chown borgUser /scripts
COPY ./borg-scripts/* /scripts/
RUN chown borgUser /scripts/*
RUN chmod +x /scripts/*

# Create the cron for daily backups
RUN echo "00 12 * * * /bin/sh /scripts/backup.sh 2>&1 | logger -t backup_script -p notice" > /etc/crontabs/borgUser

# Set the entrypoint script
ENTRYPOINT [ "/bin/sh", "/scripts/entry.sh" ]

# Run as user account
USER borgUser
