# Emailqueue docker #
**A dockerized, fast, simple yet very efficient email queuing system**

By Tin.cat (https://tin.cat)

This is a docker compose project for Emailqueue (https://github.com/tin-cat/emailqueue).

Almost anyone who has created a web application that sends emails to users in the form of newsletters, notifications, etc. has tried first to simply send the email from their code using the PHP email functions, or maybe even some advanced emailing library like the beautifully crafted PHPMailer (https://github.com/Synchro/PHPMailer). Sooner or later, though, they come to realize that triggering an SMTP connection from within their code is not the most efficient way to make a web application communicate via email with their users, mostly because this will make your code responsible about any SMTP connection errors and, specially, add all the SMTP delays to the user experience.

This is where solutions like Emailqueue come in handy: Emailqueue is not an SMTP relay, and not an email sending library like PHPMailer (though it uses PHPMailer for final deliver, actually). Think of it as an intermediate, extremely fast, post office where all the emails your application needs to send are temporarily stored, ordered and organized, this is how it works:

* Your application needs to send an email to a user (or 10 thousand emails to 10 thousand users), so instead of using the PHP mail functions or PHPMailer, it simply adds the email to Emailqueue. You can add emails to Emailqueue by injecting directly into Emailqueue's database or using the provided PHP class.

* The insertion is made as fast as possible, and your application is free to go. Emailqueue will take care of them.

* Every minute, a cronjob calls the Emailqueue's delivery script, completely apart from your running application. Emailqueue checks the queue and sends the queued emails at its own pace. You can configure a delay between each email and the maximum number of emails sent each minute to even tune the delivery speed and be more friendly to external SMTPs.

* Emailqueue even does some basic job at retrying emails that cannot be sent for whatever reason, and stores a history of detected incidences.

* Sent emails are stored on emailqueue's database for you to check who received what. A purge script can be regularly called via cronjob to automatically delete old, already sent emails to avoid your emailqueue database grow too big.

# Best features #
* Inject any number of emails super-fast and inmediately free your app to do other things. Let Emailqueue do the job in the background.
* Prioritize emails: Specify a priority when injecting an email and it will be sent before any other queued emails with lower priorities. E.g: You can inject 100k emails for a newsletter with priority 10 (they will take a while to be sent), and still inject an important email (like a password reminder message) with priority 1 to be sent ASAP even before the huge newsletter has been sent.
* Schedule emails: Inject now an email and specify a future date/time for a scheduled delivery.
* The code is quite naive, built in the early 2000s. But boy, it's been tested! This means it will be very easy for you if you decide to branch/fork it and improve it. Emailqueue is a funny grown old man.

# How to get it running #
Thanks to docker, getting an Emailqueue server up and running is extremely simple. You'll need to have **docker**, **docker-compose** and **make** installed.

* First, clone this repository:

	`$ git clone https://github.com/tin-cat/emailqueue-docker.git`

* Now bring the server up by running:

	`$ make up`

* The first time you bring it up, the docker images will be built and it will take a few minutes. When it's finished, you'll have your Emailqueue server running.
* You can run some basic commands via make. Run this to see the available options:

	`$ make help`

* You can access Emailqueue's monitoring front end by accessing this URL in your browser:

	`http://<server address>:8081/frontend`


# How to use via API calls #
The API endpoint URL would be like: http://<server address>:8081/api

Call your endpoint by making an HTTP request with the a parameter called ***q*** containing a JSon with the following keys:

* key: The API_KEY as defined in your application.config.inc.php
* message: An array defining the email message you want to inject, with the keys as defined in the "Emailqueue injection keys" section of this document.
  * Unfortunately, you cannot yet attach images when calling Emailqueue via API, so the "attachments" and "is_embed_images" keys won't have any affect when calling the API.

An example value for the ***q*** POST parameter to inject a single email would be:

```
	{
		"key":"your_api_key",
		"message": {
			"from":"me@domain.com",
			"to":"him@domain.com",
			"subject":"Just testing",
			"content":"This is just an email to test Emailqueue"
		}
	}
```

To inject multiple messages in a single API call, use the key "messages" instead of "message":
  * messages: An array of arrays defining the email messages, where each array defining the email message has the keys as defined in the "Emailqueue injection keys" section of this document.

An example value for the ***q*** POST parameter to inject multiple emails would be:

```
	{
		"key":"your_api_key",
		"messages": {
			{
				"from":"me@domain.com",
				"to":"him@domain.com",
				"subject":"Just testing",
				"content":"This is just an email to test Emailqueue"
			},
			{
				"from":"me@domain.com",
				"to":"him@domain.com",
				"subject":"Testing again",
				"content":"This is another test"
			}
		}
	}
```

The API will respond with a Json object containing the following keys:

 * result: True if the email or emails were injected ok, false otherwise.
 * errorDescription: A decription of the error, if any.

 Take a look at the provided example_api.php in Emailqueue's repository to see an example on how to call the API in PHP.

# Emailqueue injection keys #
Whenever you inject an email using the emailqueue_inject class, calling the API or manually inserting into Emailqueue's database, these are the keys you can use and their description:

  * **foreign_id_a**: Optional, an id number for your internal records. e.g. Your internal id of the user who has sent this email.
  * **foreign_id_b**: Optional, a secondary id number for your internal records.
  * **priority**: The priority of this email in relation to others: The lower the priority, the sooner it will be sent. e.g. An email with priority 10 will be sent first even if one thousand emails with priority 11 have been injected before.
  * **is_immediate**: Set it to true to queue this email to be delivered as soon as possible. (doesn't overrides priority setting)
  * **is_send_now**: Set it to true to make this email be sent right now, without waiting for the next delivery call. This effectively gets rid of the queueing capabilities of emailqueue and can delay the execution of your script a little while the SMTP connection is done. Use it in those cases where you don't want your users to wait not even a minute to receive your message.
  * **date_queued**: If specified, this message will be sent only when the given timestamp has been reached. Leave it to false to send the message as soon as possible. (doesn't overrides priority setting)
  * **is_html**: Whether the given "content" parameter contains HTML or not.
  * **from**: The sender email address
  * **from_name**: The sender name
  * **to**: The addressee email address
  * **replyto**: The email address where replies to this message will be sent by default
  * **replyto_name**: The name where replies to this message will be sent by default
  * **subject**: The email subject
  * **content**: The email content. Can contain HTML (set is_html parameter to true if so).
  * **content_nonhtml**: The plain text-only content for clients not supporting HTML emails (quite rare nowadays). If set to false, a text-only version of the given content will be automatically generated.
  * **list_unsubscribe_url**: Optional. Specify the URL where users can unsubscribe from your mailing list. Some email clients will show this URL as an option to the user, and it's likely to be considered by many SPAM filters as a good signal, so it's really recommended.
  * **attachments**: Optional. An array of hash arrays specifying the files you want to attach to your email. See example.php for an specific description on how to build this array.
  * **is_embed_images**: When set to true, Emailqueue will find all the <img ... /> tags in your provided HTML code on the "content" parameter and convert them into embedded images that are attached to the email itself instead of being referenced by URL. This might cause email clients to show the email straightaway without the user having to accept manually to load the images. Setting this option to true will greatly increase the bandwidth usage of your SMTP server, since each message will contain hard copies of all embedded messages. 10k emails with 300Kbs worth of images each means around 3Gb. of data to be transferred!

# Please #
Do not use Emailqueue to send unsolicited email, or emails about animal abuse.

# License #
Emailqueue is released under the GNU GPL v2.0 (See LICENSE file). Emailqueue includes PHPMailer (https://github.com/Synchro/PHPMailer), which is also licensed under GNU GPL v2.0

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.