var Mandrill = require('mandrill');
Mandrill.initialize('sTVCGzwudL8IpBZD6IWhgQ');

var PUSH_TYPE_NEW_MESSAGE = 101;
var PUSH_TYPE_SUBSCRIPTION = 102;

Parse.Cloud.beforeSave("Subscription", function(request, response) {
	var object = request.object;
	
	if (object.get("channel") != null) {
		object.set("channelId", object.get("channel").id);
	}
	
	// Let existing object updates go through
	if (!object.isNew()) {
		response.success();
	}
	
	// check for existing duplicate subscription
	
	var query = new Parse.Query("Subscription");
	query.equalTo("user", object.get("user"));
	query.equalTo("channel", object.get("channel"));
	query.first().then(function(existingObject) {
		if (existingObject) {
			// Existing object, stop initial save
			response.error("Existing object");
		} else {
			// New object, let the save go through
			response.success();
		}
	}, function (error) {
		response.error("Error performing checks or saves.");
	});
});

Parse.Cloud.afterSave("Subscription", function(request) {
	var user = request.object.get("user");
	var channel = request.object.get("channel");
	channel.fetch({
		success: function() {
			var pushQuery = new Parse.Query(Parse.Installation);
			var message = "You have subscribed to a channel.";
			
			if (channel.get("hidden") == true) {
				var subQuery = new Parse.Query("Subscription");
				subQuery.equalTo("channel", channel);
				
		 		pushQuery.matchesKeyInQuery("user", "user", subQuery);
		 		message = "Someone subscribed to your hidden channel.";
			} else {
				pushQuery.equalTo("user", user);
			}
			
			Parse.Push.send({
				where: pushQuery,
				data: {
					alert: message,
					badge: "Increment",
					type: PUSH_TYPE_SUBSCRIPTION
				}
			}, {
				success: function() {
					console.log("Push sent to " + user.id);
				},
				error: function(error) {
					console.log("Push failed to send to " + user.id);
				}
			});
		},
		error: function () {
			console.log("Channel fetch failed. Error: " + error);
		}
	});
});

Parse.Cloud.afterSave("Suggestion", function(request) {
	var suggestion = request.object;
	var message = "A new public channel has been suggested: "
			+ suggestion.get("text")
			+ "\n\nView: https://www.parse.com/apps/comms--7/collections#class/Suggestion"
		
	Mandrill.sendEmail({
		message: {
	    	text: message,
			subject: "Comms Channel Suggestion",
			from_email: "comms@parseapp.com",
			from_name: "Comms Administrator",
			to: [{
				email: "anthony.picciano@gmail.com",
			}]
	    },async: true
		},{
		success: function(httpResponse) {
			console.log("Suggestion email sent.");
		},
	  	error: function(httpResponse) {
			console.log("Suggestion email failed to send.");
		}
	});
});

Parse.Cloud.afterSave("RedemptionCode", function(request) {
	var redemptionCode = request.object;
	var message = "A redemption code was created or used: "
			+ redemptionCode.get("code")
			+ "\n\nView: https://www.parse.com/apps/comms--7/collections#class/RedemptionCode"
		
	Mandrill.sendEmail({
		message: {
	    	text: message,
			subject: "Comms Redemption Code Usage",
			from_email: "comms@parseapp.com",
			from_name: "Comms Administrator",
			to: [{
				email: "anthony.picciano@gmail.com",
			}]
	    },async: true
		},{
		success: function(httpResponse) {
			console.log("Redemption Code email sent.");
		},
	  	error: function(httpResponse) {
			console.log("Redemption Code email failed to send.");
		}
	});
});


Parse.Cloud.afterDelete("Subscription", function(request) {
	var user = request.object.get("user");
	var pushQuery = new Parse.Query(Parse.Installation);
	var channel = request.object.get("channel");
	var message = "You have unsubscribed from a channel.";
	
	channel.fetch({
		success: function() {
			if (channel.get("hidden") == true) {
				var subQuery = new Parse.Query("Subscription");
				subQuery.equalTo("channel", channel);
				
		 		pushQuery.matchesKeyInQuery("user", "user", subQuery);
		 		message = "Someone unsubscribed from your hidden channel.";
			} else {
				pushQuery.equalTo("user", user);
			}
		
			Parse.Push.send({
				where: pushQuery,
				data: {
					alert: message,
					badge: "Increment",
					type: PUSH_TYPE_SUBSCRIPTION
				}
			}, {
				success: function() {
					console.log("Push sent to " + user.id);
				},
				error: function(error) {
					console.log("Push failed to send to " + user.id);
				}
			});
		
			if (channel.get("hidden") == true) {
				var query = new Parse.Query("Subscription");
				query.equalTo("channel", channel);
				query.first().then(function(existingSubscription) {
					if (!existingSubscription) {
						channel.destroy();
						console.log("Deleting " + channel.get("name"));
					}
				});
			}
		}
	});
});

Parse.Cloud.afterDelete("Channel", function(request) {
  	var query = new Parse.Query("Message");
  	query.equalTo("channel", request.object);
  	query.find({
    	success: function(messages) {
			Parse.Object.destroyAll(messages, {
				success: function() {},
				error: function(error) {
					console.error("Error deleting channel messages " + error.code + ": " + error.message);
        		}
      		});
    	},
		error: function(error) {
			console.error("Error finding channel messages " + error.code + ": " + error.message);
    	}
  	});
  	
  	query = new Parse.Query("Subscription");
  	query.equalTo("channel", request.object);
  	query.find({
    	success: function(messages) {
			Parse.Object.destroyAll(messages, {
				success: function() {},
				error: function(error) {
					console.error("Error deleting channel subscriptions " + error.code + ": " + error.message);
        		}
      		});
    	},
		error: function(error) {
			console.error("Error finding channel subscriptions " + error.code + ": " + error.message);
    	}
  	});
});

Parse.Cloud.afterDelete(Parse.User, function(request) {
	query = new Parse.Query("Message");
  	query.equalTo("recipient", request.object);
  	query.find({
    	success: function(messages) {
			Parse.Object.destroyAll(messages, {
				success: function() {
					console.log("Deleted user's messages.");
				},
				error: function(error) {
					console.error("Error deleting user's messages " + error.code + ": " + error.message);
        		}
      		});
    	},
		error: function(error) {
			console.error("Error finding user's messages " + error.code + ": " + error.message);
    	}
  	});
  	
	query = new Parse.Query("Subscription");
  	query.equalTo("user", request.object);
  	query.find({
    	success: function(messages) {
			Parse.Object.destroyAll(messages, {
				success: function() {
					console.log("Deleted user's subscriptions.");
				},
				error: function(error) {
					console.error("Error deleting user's subscriptions " + error.code + ": " + error.message);
        		}
      		});
    	},
		error: function(error) {
			console.error("Error finding user's subscriptions " + error.code + ": " + error.message);
    	}
  	});
});

Parse.Cloud.afterSave("Message", function(request) {
	var recipient = request.object.get("recipient");
	var pushQuery = new Parse.Query(Parse.Installation);
	
	if (recipient) {
		pushQuery.equalTo("user", recipient);
	} else {
		var channel = request.object.get("channel");
		var subQuery = new Parse.Query("Subscription");
		subQuery.equalTo("channel", channel);
		
 		pushQuery.matchesKeyInQuery("user", "user", subQuery);
	}
	
	Parse.Push.send({
		where: pushQuery,
		data: {
			alert: "New message in subscribed channel.",
			badge: "Increment",
			sound: "nnn-short.aiff",
			type: PUSH_TYPE_NEW_MESSAGE
		}
	}, {
		success: function() {
			console.log("Push sent for message " + request.object.id);
		},
		error: function(error) {
			console.log("Push failed to send for message " + request.object.id);
		}
	});
});

Parse.Cloud.job("destroyOldMessages", function(request, status) {
	var day = new Date();
	day.setDate(day.getDate() - request.params.daysOld);
	
	console.log("Destroying messages older than " + day);

	var query = new Parse.Query("Message");
	query.lessThan("createdAt", day);
	
	query.find({
		success: function(messages) {
			Parse.Object.destroyAll(messages, {
				success: function() {
					status.success("Destroy Old Messages completed successfully.");
				},
				error: function(error) {
					status.error("Error destroying old messages " + error.code + ": " + error.message);
				}
			});
		},
		error: function(error) {
			status.error("Error finding old messages to be destroyed " + error.code + ": " + error.message);
		}
	});
});