FROM discourse/discourse:latest

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

COPY discourse.conf /var/discourse/config/discourse.conf

EXPOSE 3000 8080
ENTRYPOINT ["/startup.sh"]