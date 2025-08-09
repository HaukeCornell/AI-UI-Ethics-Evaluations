Qualtrics.SurveyEngine.addOnload(function()
{
 // Get the current loop iteration number (1-based)
    var currentLoop = parseInt("${lm://CurrentLoopNumber}");
    
    // Simple rule: First half Human, Second half AI
    // Assuming 6 total interfaces (adjust number as needed)
    var totalInterfaces = 6;
    var halfPoint = Math.ceil(totalInterfaces / 2);
    
    // Hide both initially
    jQuery(".ai-source").hide();
    jQuery(".human-source").hide();
    
    if (currentLoop <= halfPoint) {
        // First half: Human
        jQuery(".human-source").show();
        Qualtrics.SurveyEngine.setEmbeddedData("interface_" + currentLoop + "_source", "human");
    } else {
        // Second half: AI  
        jQuery(".ai-source").show();
        Qualtrics.SurveyEngine.setEmbeddedData("interface_" + currentLoop + "_source", "ai");
    }
    
    // Also set a general tracking variable
    Qualtrics.SurveyEngine.setEmbeddedData("current_source", currentLoop <= halfPoint ? "human" : "ai");
});

Qualtrics.SurveyEngine.addOnReady(function()
{
	/*Place your JavaScript here to run when the page is fully displayed*/

});

Qualtrics.SurveyEngine.addOnUnload(function()
{
	/*Place your JavaScript here to run when the page is unloaded*/

});