(function ($) {
	$(function () {
		window.lim.plugin.softhsm = {
			init: function () {
				var that = this;
				
				$('.sidebar-nav a[href="#about"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadAbout();
	    			return false;
				});
				$('.sidebar-nav a[href="#system-information"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSystemInformation();
	    			return false;
				});
				
				// CONFIG

				$('.sidebar-nav a[href="#config_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadConfigList();
	    			return false;
				});
				$('.sidebar-nav a[href="#config_read"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadConfigRead();
	    			return false;
				});
				
				// SLOTS
				
				$('.sidebar-nav a[href="#show_slots"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadShowSlots();
					return false;
				});
				
				this.loadAbout();
			},
			//
			loadAbout: function () {
				window.lim.loadPage('/_softhsm/about.html')
				.done(function (data) {
					window.lim.display(data, '#softhsm-content');
				});
			},
			//
			loadSystemInformation: function () {
				var that = this;

				window.lim.loadPage('/_softhsm/system_information.html')
				.done(function (data) {
					window.lim.display(data, '#softhsm-content');
					that.getSystemInformation();
				});
			},
			getSystemInformation: function () {
				window.lim.getJSON('/softhsm/version')
				.done(function (data) {
					if (data.version) {
						$('#softhsm-version').text(data.version);
					}
					else {
						$('#softhsm-version i').text('failed');
					}
					
		    		if (data.program && data.program.length) {
		    			$('#softhsm-content table tbody').empty();

			    		data.program.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.program, function () {
			    			$('#softhsm-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.version)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.program && data.program.name) {
		    			$('#softhsm-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.program.name),
		    					$('<td></td>').text(data.program.version)
	    					));
			    		return;
		    		}
		    		
		    		$('#softhsm-content table td i').text('Unable to retrieve system information: unknown error.');
				})
				.fail(function () {
					$('#softhsm-version i').text('failed');
					$('#softhsm-content table td i').text('failed');
				});
			},
			//
			// CONFIG
			//
			loadConfigList: function () {
				var that = this;
				
				window.lim.loadPage('/_softhsm/config_list.html')
				.done(function (data) {
					window.lim.display(data, '#softhsm-content');
					that.getConfigList();
				});
			},
			getConfigList: function () {
				window.lim.getJSON('/softhsm/configs')
				.done(function (data) {
		    		if (data.file && data.file.length) {
		    			$('#softhsm-content table tbody').empty();
		    			
			    		data.file.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.file, function () {
			    			$('#softhsm-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.read ? 'Yes' : 'No'),
			    					$('<td></td>').text(this.write ? 'Yes' : 'No')
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.file && data.file.name) {
		    			$('#softhsm-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.file.name),
		    					$('<td></td>').text(data.file.read ? 'Yes' : 'No'),
		    					$('<td></td>').text(data.file.write ? 'Yes' : 'No')
	    					));
		    			return;
		    		}
		    		
		    		$('#softhsm-content table td i').text('No config files found');
				})
				.fail(function (jqXHR) {
					$('#softhsm-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read config file list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadConfigRead: function () {
				var that = this;
				
				window.lim.loadPage('/_softhsm/config_read.html')
				.done(function (data) {
					window.lim.display(data, '#softhsm-content');
		    		$('#softhsm-content select').prop('disabled',true);
		    		$('#softhsm-content .selectpicker').selectpicker();
		    		$('#softhsm-content form').submit(function () {
	    				var file = $('#softhsm-content select option:selected').text();
		    			if (file) {
		    				$('#softhsm-content form').remove();
		    				$('#softhsm-content').append(
		    					$('<p></p>').append(
		    						$('<i></i>')
		    						.text('Loading zone file '+file+' ...')
	    						));
		    				window.lim.getJSON('/softhsm/config', {
		    					file: {
		    						name: file
		    					}
		    				})
		    				.done(function (data) {
		    					if (data.file && !data.file.length && data.file.name) {
		    						$('#softhsm-content p').text('Content of the config file '+file);
		    						$('#softhsm-content').append(
		    							$('<pre class="prettyprint linenums"></pre>')
		    							.text(data.file.content)
		    							);
		    						prettyPrint();
		    						return;
		    					}
		    					
								$('#softhsm-content p')
								.text('Config file '+file+' not found');
		    				})
							.fail(function (jqXHR) {
								$('#softhsm-content p')
								.text('Unable to read config file '+file+': '+window.lim.getXHRError(jqXHR))
								.addClass('text-error');
							});
		    			}
		    			return false;
		    		});
		    		$('#softhsm-content #submit').prop('disabled',true);
		    		that.getConfigRead();
				});
			},
			getConfigRead: function () {
				window.lim.getJSON('/softhsm/configs')
				.done(function (data) {
		    		if (data.file && data.file.length) {
		    			$('#softhsm-content select').empty();
		    			
			    		data.file.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.file, function () {
			    			$('#softhsm-content select').append(
			    				$('<option></option>').text(this.name)
			    				);
			    		});
			    		$('#softhsm-content select').prop('disabled',false);
			    		$('#softhsm-content .selectpicker').selectpicker('refresh');
			    		$('#softhsm-content #submit').prop('disabled',false);
			    		return;
		    		}
		    		else if (data.file && data.file.name) {
		    			$('#softhsm-content select')
		    			.empty()
		    			.append($('<option></option>').text(data.file.name));

			    		$('#softhsm-content select').prop('disabled',false);
			    		$('#softhsm-content .selectpicker').selectpicker('refresh');
			    		$('#softhsm-content #submit').prop('disabled',false);
		    			return;
		    		}
		    		
		    		$('#softhsm-content option').text('No config files found');
		    		$('#softhsm-content .selectpicker').selectpicker('refresh');
				})
				.fail(function (jqXHR) {
					$('#softhsm-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read config file list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			// SLOTS
			//
			loadShowSlots: function () {
				var that = this;
				window.lim.loadPage('/_softhsm/show_slots.html')
				.done(function (data) {
					window.lim.display(data, '#softhsm-content');
					that.getShowSlots();
				});
			},
			getShowSlots: function () {
				window.lim.getJSON('/softhsm/show_slots')
				.done(function (data) {
		    		if (data.slot && data.slot.length) {
		    			$('#softhsm-content table tbody').empty();
		    			
			    		data.slot.sort(function (a, b) {
			    			return (a.id > b.id) ? 1 : ((a.id < b.id) ? -1 : 0);
			    		});

			    		$.each(data.slot, function () {
			    			$('#softhsm-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.id),
			    					$('<td></td>').text(this.token_label),
			    					$('<td></td>').text(this.token_present ? 'Yes' : 'No'),
			    					$('<td></td>').text(this.token_initialized ? 'Yes' : 'No'),
			    					$('<td></td>').text(this.user_pin_initialized ? 'Yes' : 'No')
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.slot && data.slot.id) {
		    			$('#softhsm-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.slot.id),
		    					$('<td></td>').text(data.slot.token_label),
		    					$('<td></td>').text(data.slot.token_present ? 'Yes' : 'No'),
		    					$('<td></td>').text(data.slot.token_initialized ? 'Yes' : 'No'),
		    					$('<td></td>').text(data.slot.user_pin_initialized ? 'Yes' : 'No')
	    					));
		    			return;
		    		}
		    		
		    		$('#softhsm-content table td i').text('No slots found');
				})
				.fail(function (jqXHR) {
					$('#softhsm-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read slots: '+window.lim.getXHRError(jqXHR))
						);
				});
			}
		};
		window.lim.plugin.softhsm.init();
	});
})(window.jQuery);
