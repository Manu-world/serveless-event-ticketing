import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import boto3

class EmailService:
    def __init__(self, logger):
        self.provider = os.environ.get('EMAIL_PROVIDER', 'smtp').lower()
        self.logger = logger
        
        # SMTP Config
        self.smtp_host = os.environ.get('SMTP_HOST', 'smtp.gmail.com')
        self.smtp_port = int(os.environ.get('SMTP_PORT', 587))
        self.smtp_user = os.environ.get('SMTP_USER')
        self.smtp_password = os.environ.get('SMTP_PASSWORD')
        
        # SES Config (lazy init)
        self.ses_client = None

    def send_confirmation(self, to_email, event_id, ticket_id):
        subject = "Event Registration Confirmed!"
        body = f"Success! You are registered for Event: {event_id}.\nYour Registration Ticket ID is: {ticket_id}"
        
        self.logger.info(f"Attempting to send email via {self.provider} to {to_email}")

        if self.provider == 'smtp':
            self._send_smtp(to_email, subject, body)
        elif self.provider == 'ses':
            self._send_ses(to_email, subject, body)
        elif self.provider == 'none':
            self.logger.info(f"EMAIL_PROVIDER is 'none'. Skipping email to {to_email}")
        else:
            self.logger.warning(f"Unknown EMAIL_PROVIDER: {self.provider}. Skipping email.")

    def _send_smtp(self, to_email, subject, body):
        if not self.smtp_user or not self.smtp_password:
            self.logger.error("SMTP credentials not configured. Cannot send email.")
            return

        msg = MIMEMultipart()
        msg['From'] = self.smtp_user
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        try:
            server = smtplib.SMTP(self.smtp_host, self.smtp_port)
            server.starttls()
            server.login(self.smtp_user, self.smtp_password)
            server.send_message(msg)
            server.quit()
            self.logger.info("SMTP email sent successfully")
        except Exception as e:
            self.logger.error(f"Failed to send SMTP email: {str(e)}")
            # We don't raise here, we don't want to fail the registration if email fails

    def _send_ses(self, to_email, subject, body):
        if not self.ses_client:
            self.ses_client = boto3.client('ses')
            
        try:
            self.ses_client.send_email(
                Source=self.smtp_user or "noreply@example.com", # Fallback if not set
                Destination={'ToAddresses': [to_email]},
                Message={
                    'Subject': {'Data': subject},
                    'Body': {'Text': {'Data': body}}
                }
            )
            self.logger.info("SES email sent successfully")
        except Exception as e:
            self.logger.error(f"Failed to send SES email: {str(e)}")
