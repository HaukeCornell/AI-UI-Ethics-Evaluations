Qualtrics.SurveyEngine.addOnload(function()
{
    // Get the current loop iteration number (1-based)
    var currentLoop = parseInt("${lm://CurrentLoopNumber}");
    
    // Debug: Log the current loop number
    console.log("Current loop: " + currentLoop);
    
    // Simple rule: First half Human, Second half AI
    // Assuming 6 total interfaces (adjust number as needed)
    var totalInterfaces = 6;
    var halfPoint = Math.ceil(totalInterfaces / 2); // This will be 3
    
    // Debug: Log the half point
    console.log("Half point: " + halfPoint);
    
    // Hide both initially
    jQuery(".ai-source").hide();
    jQuery(".human-source").hide();
    
    if (currentLoop <= halfPoint) {
        // First half: Human (loops 1, 2, 3)
        console.log("Showing human source");
        jQuery(".human-source").show();
        Qualtrics.SurveyEngine.setEmbeddedData("interface_" + currentLoop + "_source", "human");
    } else {
        // Second half: AI (loops 4, 5, 6)
        console.log("Showing AI source");
        jQuery(".ai-source").show();
        Qualtrics.SurveyEngine.setEmbeddedData("interface_" + currentLoop + "_source", "ai");
    }
    
    // Also set a general tracking variable
    Qualtrics.SurveyEngine.setEmbeddedData("current_source", currentLoop <= halfPoint ? "human" : "ai");
});

Qualtrics.SurveyEngine.addOnReady(function()
{
    // Alternative approach: Try again on ready in case DOM isn't fully loaded
    var currentLoop = parseInt("${lm://CurrentLoopNumber}");
    var halfPoint = 3; // For 6 interfaces
    
    // Check if elements exist
    if (jQuery(".ai-source").length > 0 && jQuery(".human-source").length > 0) {
        if (currentLoop <= halfPoint) {
            jQuery(".human-source").show();
            jQuery(".ai-source").hide();
        } else {
            jQuery(".ai-source").show();
            jQuery(".human-source").hide();
        }
    } else {
        console.log("Source elements not found!");
    }
});

Qualtrics.SurveyEngine.addOnUnload(function()
{
    /*Place your JavaScript here to run when the page is unloaded*/
});