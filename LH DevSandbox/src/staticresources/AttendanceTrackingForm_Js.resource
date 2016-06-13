var TrackerForm = {};
(function() {
        function findUosElement(localSelector) {
            return $("#uosTable " + localSelector);
        }
    
        function uiPrepareUosRows() {
            var targetElement = $('#uosTable');
            targetElement.find("select").each(function(index, el) { 
                var selectValue = $(el).data("value");
                $(el).val(selectValue);
            });
            var rows = targetElement.find('tr');
            rows.each(function(index, currentRow) {
                uiPrepareUosRow(currentRow); 
            });
        }
        
        function uiPrepareUosRow(row) {
            var currentRow = $(row);
            var rowType = currentRow.data('type');
            if (rowType === 'Header') {
                return;
            }

            var authDropDownElement = currentRow.find(".td-authorization select");
            authDropDownElement.children('option').each(function(index, el) {
                var optionElement = $(el);
                if (optionElement.val() !== '') {
                    optionElement.remove();
                }
            });

            currentRow.find(".date").each(function(index, el) {
                var dateElement = $(el);
                var datePickerClass = 'hasDatepicker';
                if (dateElement.hasClass(datePickerClass)) {
                    dateElement.removeClass(datePickerClass);
                    dateElement.removeAttr('id');
                }
                dateElement.datepicker();
            });
            
            var copyLink = currentRow.find(".td-action a.copyAction");
            var deleteLink = currentRow.find(".td-action a.deleteAction");
            var cloneLink = currentRow.find(".td-action a.cloneAction");
            if (rowType === 'Sample') {
                copyLink.show();
                deleteLink.hide();
                cloneLink.hide();
            }
            else {
                if (copyLink) {
                    copyLink.hide();
                }
                deleteLink.show();
                cloneLink.show();
                var participantColumn = currentRow.find('.td-participant');
                var participantId = participantColumn.data('participant');
                var populateAuthDropDown = function(row, authData) {
                    if (authData.length > 0) {
                        var authDropDownElement = row.find(".td-authorization select");
                        var authValue = authDropDownElement.data('value');
                        var option;
                        for (var i = 0; i < authData.length; i ++) {
                            option = $('<option>', {value : authData[i].id});
                            option.text(authData[i].value);
                            if (authValue && authData[i].id === authValue) {
                                option.attr('selected', 'selected');
                            }
                            authDropDownElement.append(option);
                        }
                    }
                    
                };
                var authData = pageData.authorizations[participantId];
                if (authData) {
                    populateAuthDropDown(currentRow, authData);
                }
                else {
                    console.log('Fetching auth for participant ' + participantId);
                    AttendanceTrackingFormController.fetchAuthorizations(
                        participantId, function(result, event) {
                            if (event.status) {
                                pageData.authorizations[participantId] = result;
                                populateAuthDropDown(currentRow, result);
                            }
                            else {
                                // This means there was an error fetching authorization.
                                // Do nothing! The drop-down doesn't get populated.
                                console.log('Error fetching authorizations for participant - ' + event.message);
                            }
                        });
                    
                }
            }
            
        }

        function getAlreadyAddedParticipants() {
            var rows = findUosElement(' .td-participant'); 
            var alreadyAddedParticipants = {};
            rows.each(
                function() {
                    alreadyAddedParticipants[$(this).data('participant')]= true;
                }
            );
            return alreadyAddedParticipants;
        }

        function getUnassignedParticipants() {
            var alreadyAddedParticipants = getAlreadyAddedParticipants();
            participantsEligibleForAdd = pageData.programParticipants.filter(function(participant) {
                return (alreadyAddedParticipants[participant.id] ? false : true);
            });
            return participantsEligibleForAdd;    
        }

        function chooseParticipantForAdd() {
            
            var participantId = TrackerForm.participantChooserDialog.getChosenId();
            var participantName = TrackerForm.participantChooserDialog.getChosenName();
            
            if (participantId === undefined || participantId === '') {
                // No valid participant chosen.  Do nothing, stay in the dialog.
                return;
            }
            
            var lastRow = findUosElement('tr:last-child');
            
            var sourceRow;
            
            var callerInfo = TrackerForm.participantChooserDialog.getCallerInfo();
            if (callerInfo.sourceType === 'CloneSampleRecord') {
                sourceRow = findUosElement('tr[data-type="Sample"]');
            }
            else if (callerInfo.sourceType === 'CloneDataRecord') {
                var targetColumn = findUosElement('tr td[data-participant="' + callerInfo.participantId + '"]');
                sourceRow = targetColumn.closest('tr');
            }
            else {
                sourceRow = lastRow;
            }
            
            var newRow = sourceRow.clone();
            newRow.attr('data-id', '');
            newRow.attr('data-type', 'New');
            newRow.addClass('tr-new');
            
            var participantColumn = newRow.find('.td-participant');
            participantColumn.attr('data-participant', participantId);
            participantColumn.text(participantName);
            
            var rowTypeColumn = newRow.find('.td-rowType');
            rowTypeColumn.text('New');
            
            lastRow.after(newRow);
            uiPrepareUosRow(newRow);

            TrackerForm.participantChooserDialog.close();
        }
    
        function getWorkshopId() {
            return $('.workshop').val();
        }
    
        function getClassComponentId() {
            return $('.classComponent').val();
        }

        var getCurrentAttendanceFormUrl = function() {
            return 'AttendanceTrackingForm?workshopId=' 
            + getWorkshopId() + '&classId=' + getClassComponentId();
        };

        var setErrorText = function(error) {
            $('#errorPanel').text(error);  
        };

        var clearErrorText = function() {
            $('#errorPanel').text('');  
        };

        var setErrorHtml = function(html) {
            $('#errorPanel').empty().append(html);
        }

        var copyRows = function(limitToBlankRows) {
            var sampleRow = findUosElement('tr[data-type="Sample"]');
            var sampleRowData = {};
            sampleRow.find('td').each(function(index, el) {
                var tdElement = $(el);
                var inputElement = tdElement.find(':input');
                if (inputElement && inputElement.val() !== undefined) {
                    sampleRowData[tdElement.attr('class')] = inputElement.val();
                }
            });

            var copyToSingleRow = function(targetRow) {
                targetRow.find('td').each(function(index, el) {
                    var tdElement = $(el);
                    var columnInputValue = sampleRowData[tdElement.attr('class')];
                    if (columnInputValue !== undefined) {
                        var inputElement = tdElement.find(':input');
                        inputElement.val(columnInputValue);
                    }
                });
            };
            
            findUosElement('tr[data-type="New"]').each(function(index, newRow) {
                copyToSingleRow($(newRow));
            });
    
            if (!limitToBlankRows) {
                findUosElement('tr[data-type="Existing"]').each(function(index, newRow) {
                    copyToSingleRow($(newRow));
                });
            }
        };
    
        TrackerForm.copyToBlankRows = function() {
            copyRows(true);
        }
    
        TrackerForm.copyToAllRows = function() {
            copyRows(false);
        };
    
    

        TrackerForm.deleteUos = function(deleteLinkEl) {
            var callback = function() {
                var uosRow = $(deleteLinkEl).closest('tr');
                var uosId = uosRow.data('id');
                if (uosId && uosId !== '') {
                    TrackerForm.mask.show();
                    AttendanceTrackingFormController.deleteUos(
                        uosId, function(result, event) {
                            TrackerForm.mask.hide();
                            if (event.status) {
                                uosRow.remove();
                                clearErrorText();
                                alert('Successfully deleted!');
                            }
                            else {
                                setErrorText(event.message);
                            }
                    });
                }
                else {
                    uosRow.remove();
                }
            };
            this.deleteConfirmDialog.show(callback);
        };

        TrackerForm.cloneUos = function(cloneLinkEl) {
            var uosRow = $(cloneLinkEl).closest('tr');
            var pId = uosRow.find('.td-participant').data('participant');
            this.participantChooserDialog.open({sourceType: 'CloneDataRecord', participantId: pId});
        };

        TrackerForm.cancel = function() {
            this.cancelConfirmDialog.show(function() {
                location.href = pageData.workshopDetailPageUrl;
            });
        };

        TrackerForm.saveUos = function() {
            var uosList = [];
            findUosElement("tr").each(function(index, el) { 
                var element = $(el);
                var rowType = element.data('type');
                if (rowType === 'Header' || rowType === 'Sample') return;
                var elementId = element.data('id');
                var participantColumn = element.find('.td-participant');
                uosList.push({
                	uosId: elementId,
                    participantId: participantColumn.data('participant'),
                    participantName: participantColumn.text(),
                    serviceProviderId: element.find('.td-serviceProvider select').val(),
                    serviceDate: element.find('.td-serviceDate input').val(), 
                    serviceTime: element.find('.td-serviceTime input').val(), 
                    cancelReason: element.find('.td-cancelReason select').val(),
                    paymentSourceId: element.find('.td-paymentSource select').val(),
                    authorizationId: element.find('.td-authorization select').val(),
                    numberOfAdditionalPeople: element.find('.td-numberOfAdditionalPeople input').val(),
                    billableUnits: element.find('.td-billableUnits input').val(),
                    typeOfUnits: element.find('.td-typeOfUnits select').val(),
                    progressLessonNotes: element.find('.td-progressLessonNotes textarea').val(),
                });
            });
            
            var errors = validateUosList(uosList);
            if (errors && errors.length > 0) {
                displayValidationErrors(errors);
                return;
            }
            
            TrackerForm.mask.show();        
            AttendanceTrackingFormController.upsertUosList(
                getWorkshopId(), getClassComponentId(), uosList, function(result, event) {
                TrackerForm.mask.hide();
                if (event.status) {
                    if (result.success) {
                        clearErrorText();
                        alert('Successfully saved!');
                        location.href = pageData.workshopDetailPageUrl;
                    }
                    else {
                        var record;
                        var errorText = '';
                        if (result.hasRowLevelErrors) {
                            var errors = [];
                            for (var i = 0; i < result.uosResultList.length; i ++) {
                                record = result.uosResultList[i];
                                if (!record.success) {
                                    errors.push({
                                        participantName: record.participantName,
                                        errorMessage: record.errorMessage
                                    })
                                }
                            }
                            displayValidationErrors(errors);
                        }
                        else {
                            setErrorText('System error: Message - ' + result.errorMessage + ', Stack trace: ' + result.errorStackTrace);
                        }
                    }
                }
                else if (event.type === 'exception') {
                    setErrorText(event.message);
                }
                else {
                    setErrorText(event.message);
                }
            });
        };

        function validateUosList(uosList) {
            var uos;
            var value;
            var errors = [];
            var collectError = function(uos, fieldName, errorMessage) {
		errors.push({
		    participantName: uos.participantName,
                    fieldName: fieldName,
                    errorMessage: errorMessage
		});
            };
            var validateAdditionalPeople = function(uos) {
                var errorMessage = 'Should be a number between 0 and 10';
                var fieldName = 'Additional People';
                if (!$.isNumeric(uos.numberOfAdditionalPeople)) {
                    collectError(uos, fieldName, errorMessage);
                }
                else {
                    value = parseInt(uos.numberOfAdditionalPeople);
                    if (value < 0 || value > 10) {
                        collectError(uos, fieldName, errorMessage);
                    }
                }
            };
            var validateBillableUnits = function(uos) {
                var errorMessage = 'Should be numeric';
                if (!$.isNumeric(uos.billableUnits)) {
                    collectError(uos, 'Billable Units', errorMessage);
                }
            };
            var validatePaymentSource = function(uos) {
                var errorMessage = 'Required field';
                if (uos.paymentSourceId === '') {
                    collectError(uos, 'Payment Source', errorMessage);
                }
            };
            for (var i = 0; i < uosList.length; i ++) {
                uos = uosList[i];
                validateAdditionalPeople(uos);
                validateBillableUnits(uos);
                validatePaymentSource(uos);
            }
            return errors;
        }

        function displayValidationErrors(errors) {
            var listHtmlElement = $('<ul>');
            for (var i = 0; i < errors.length; i ++) {
                listHtmlElement.append('<li>' 
                    + errors[i].participantName
                    + (errors[i].fieldName ? ': ' + errors[i].fieldName : '')
                    + ': ' + errors[i].errorMessage
                    + '.'
                    + '</li>');
            }
            setErrorHtml(listHtmlElement);
        }

        /** Anonymouns function to create all UI elements needed for the page **/
        (function() {
            /**
            $('.workshop').select2({
                placeholder: "Select a workshop",
                allowClear: true
            });
            
            $('.classComponent').select2({
                placeholder: "Select a class",
                allowClear: true
            });
            **/
            
            uiPrepareUosRows();
            TrackerForm.mask = function() {
                var dialog = $( "#progressbar" ).dialog({
                    modal: true,
                    autoOpen: false
                });
                return {
                   show: function() {dialog.dialog("open");},
                   hide: function() {dialog.dialog("close");},
                };
            }();
            
            function ConfirmationDialog(divId) {
                var data = {};
                var dialog = $('#' + divId).dialog({
                    resizable: false,
                    autoOpen: false,
                    height:220,
                    modal: true,
                    buttons: {
                       Yes: function() {
                           $(this).dialog( "close" );
                           data.callback();
                           data = {};
                       },
                       No: function() {
                           data = {};
                           $(this).dialog( "close" );
                       }
                    }
                });
                this.show = function(callback) {
                    data.callback = callback;
                    dialog.dialog("open");
                };
            }
            
            TrackerForm.cancelConfirmDialog = new ConfirmationDialog('cancelConfirmDiv');
            TrackerForm.deleteConfirmDialog = new ConfirmationDialog('deleteConfirmDiv');
            
            TrackerForm.participantChooserDialog = function() {
                var dialog = $("#participantChooserDiv").dialog({
                    autoOpen: false,
                    height: 200,
                    width: 350,
                    modal: true,
                    buttons: {
                        "Choose": chooseParticipantForAdd
                    }
                });
                return {
                   open: function(callerInfo) {
                       this.data = {};
                       this.data.callerInfo =  callerInfo;
                       var autoCompleteEl = $("#newParticipant");
                       autoCompleteEl.autocomplete("option", {source: getUnassignedParticipants()});
                       autoCompleteEl.val('');
                       dialog.dialog("open");
                   },
                   close: function() {
                       this.data = {};
                       dialog.dialog("close");
                   },
                   clearParticipantData: function() {
                       this.data.chosenId = '';
                       this.data.chosenName = '';
                   },
                   getChosenId: function() {
                       return this.data.chosenId;
                   },
                   getChosenName: function() {
                       return this.data.chosenName;
                   },
                   getCallerInfo: function() {
                       return this.data.callerInfo;
                   },
                   setChosenId: function(id) {
                       this.data.chosenId = id;
                   },
                   setChosenName: function(name) {
                       this.data.chosenName = name;
                   },
                };
            }();

            $("#newParticipant").autocomplete({
                source: getUnassignedParticipants(),
                /**
                 // Remotely fetch participants, commented out for now!
                source: function(request, response) {
                    AttendanceTrackingFormController.fetchParticipants(
                        request.term, getWorkshopId(), getClassComponentId(), 
                        function(participantData, event) {
                            if (event.status) {
                                response(participantData);
                            }
                            else {
                                //alert(event.message);
                            }
                    });
                },
                */
                minLength: 2,
                select: function(event, ui) {
                    if (ui.item) {
                        TrackerForm.participantChooserDialog.setChosenId(ui.item.id);
                        TrackerForm.participantChooserDialog.setChosenName(ui.item.value);
                    }
                },
                change: function(event, ui) {
                    if (ui && ui.item) {
                        // Do nothing if there is a valid item picked from auto-complete drop-down.
                    }
                    else {
                        // Invalidate data since a proper value wasn't picked from auto-complete drop-down.
                        TrackerForm.participantChooserDialog.clearParticipantData();
                    }
                }
            });
            
        })();

})();
