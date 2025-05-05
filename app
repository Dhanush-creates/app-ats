<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ATS Resume Expert</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            text-align: center;
            color: #4B8BBE;
            margin-bottom: 30px;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
        }
        textarea {
            width: 100%;
            height: 200px;
            padding: 10px;
            margin-bottom: 20px;
            border: 1px solid #ccc;
            border-radius: 4px;
            resize: vertical;
        }
        .file-input {
            margin-bottom: 20px;
        }
        .file-label {
            display: block;
            margin-bottom: 10px;
        }
        .success-message {
            color: #28a745;
            margin-top: 5px;
            display: none;
        }
        .warning-message {
            color: #dc3545;
            margin-top: 5px;
            display: none;
        }
        .button-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        button {
            background-color: #4B8BBE;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            flex-basis: 48%;
        }
        button:hover {
            background-color: #3a7ca5;
        }
        .results {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #4B8BBE;
            display: none;
        }
        .spinner {
            text-align: center;
            display: none;
            margin: 20px 0;
        }
        .spinner::after {
            content: '';
            display: inline-block;
            width: 30px;
            height: 30px;
            border: 4px solid rgba(0, 0, 0, 0.1);
            border-radius: 50%;
            border-top-color: #4B8BBE;
            animation: spin 1s ease-in-out infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>ATS Resume Expert</h1>
        
        <div>
            <label for="jobDescription">Enter the job description below</label>
            <textarea id="jobDescription" placeholder="Paste job description here..."></textarea>
        </div>
        
        <div class="file-input">
            <label class="file-label" for="resumeUpload">Upload your resume (PDF only)</label>
            <input type="file" id="resumeUpload" accept=".pdf">
            <div id="uploadSuccess" class="success-message">Resume uploaded successfully!</div>
        </div>
        
        <div class="button-row">
            <button id="analyzeButton">Tell me about the resume</button>
            <button id="improveButton">How can I improve my skills?</button>
        </div>
        
        <div id="warningMessage" class="warning-message"></div>
        
        <div id="spinner" class="spinner"></div>
        
        <div id="results" class="results">
            <h3>Analysis Results</h3>
            <div id="analysisResults"></div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.4.120/pdf.min.js"></script>
    <script>
        // Set worker path for pdf.js
        pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.4.120/pdf.worker.min.js';
        
        document.addEventListener('DOMContentLoaded', function() {
            const resumeUpload = document.getElementById('resumeUpload');
            const uploadSuccess = document.getElementById('uploadSuccess');
            const analyzeButton = document.getElementById('analyzeButton');
            const improveButton = document.getElementById('improveButton');
            const warningMessage = document.getElementById('warningMessage');
            const spinner = document.getElementById('spinner');
            const results = document.getElementById('results');
            const analysisResults = document.getElementById('analysisResults');
            
            let pdfText = null;
            
            // Handle file upload
            resumeUpload.addEventListener('change', async function(e) {
                const file = e.target.files[0];
                if (file && file.type === 'application/pdf') {
                    try {
                        pdfText = await extractTextFromPDF(file);
                        if (pdfText && pdfText.trim() !== '') {
                            uploadSuccess.style.display = 'block';
                            warningMessage.style.display = 'none';
                        } else {
                            warningMessage.textContent = 'No readable text found in the uploaded PDF.';
                            warningMessage.style.display = 'block';
                            uploadSuccess.style.display = 'none';
                        }
                    } catch (error) {
                        warningMessage.textContent = `Error processing PDF: ${error.message}`;
                        warningMessage.style.display = 'block';
                        uploadSuccess.style.display = 'none';
                    }
                } else {
                    warningMessage.textContent = 'Please upload a PDF file.';
                    warningMessage.style.display = 'block';
                    uploadSuccess.style.display = 'none';
                }
            });
            
            // Extract text from PDF
            async function extractTextFromPDF(file) {
                return new Promise((resolve, reject) => {
                    const reader = new FileReader();
                    reader.onload = async function(event) {
                        try {
                            const typedArray = new Uint8Array(event.target.result);
                            const loadingTask = pdfjsLib.getDocument(typedArray);
                            const pdf = await loadingTask.promise;
                            
                            let fullText = '';
                            for (let i = 1; i <= pdf.numPages; i++) {
                                const page = await pdf.getPage(i);
                                const textContent = await page.getTextContent();
                                const pageText = textContent.items.map(item => item.str).join(' ');
                                fullText += pageText + '\n';
                            }
                            resolve(fullText);
                        } catch (error) {
                            reject(error);
                        }
                    };
                    reader.onerror = reject;
                    reader.readAsArrayBuffer(file);
                });
            }
            
            // Handle button clicks
            analyzeButton.addEventListener('click', () => processRequest(1));
            improveButton.addEventListener('click', () => processRequest(2));
            
            // Process request based on button clicked
            function processRequest(promptType) {
                const jobDescription = document.getElementById('jobDescription').value;
                
                // Validate inputs
                if (!pdfText) {
                    warningMessage.textContent = 'Please upload your resume.';
                    warningMessage.style.display = 'block';
                    return;
                }
                
                if (!jobDescription.trim()) {
                    warningMessage.textContent = 'Please enter a job description.';
                    warningMessage.style.display = 'block';
                    return;
                }
                
                // Clear warnings and show spinner
                warningMessage.style.display = 'none';
                spinner.style.display = 'block';
                results.style.display = 'none';
                
                // In a real application, this would make an API call to the backend
                // For this demo, we'll simulate the response
                setTimeout(() => {
                    spinner.style.display = 'none';
                    results.style.display = 'block';
                    
                    // Simulate different responses based on prompt type
                    if (promptType === 1) {
                        simulateAnalysisResponse(jobDescription, pdfText);
                    } else {
                        simulateImprovementResponse(jobDescription, pdfText);
                    }
                }, 2000);
            }
            
            // Simulate responses (in a real app, these would come from the API)
            function simulateAnalysisResponse(jobDescription, pdfText) {
                // Simple keyword matching to simulate analysis
                const jobKeywords = extractKeywords(jobDescription);
                const resumeKeywords = extractKeywords(pdfText);
                const matches = jobKeywords.filter(keyword => 
                    resumeKeywords.some(rKeyword => 
                        rKeyword.toLowerCase().includes(keyword.toLowerCase()) || 
                        keyword.toLowerCase().includes(rKeyword.toLowerCase())
                    )
                );
                
                const matchPercentage = Math.round((matches.length / jobKeywords.length) * 100);
                
                // Generate a simulated response
                let response = `<p><strong>Resume Evaluation:</strong></p>
                <p>Based on my analysis, there appears to be a ${matchPercentage}% match between your resume and the job description.</p>
                <p><strong>Strengths:</strong></p>
                <ul>`;
                
                // Add some strengths based on matches
                for (let i = 0; i < Math.min(3, matches.length); i++) {
                    response += `<li>Good alignment with the requirement for "${matches[i]}"</li>`;
                }
                
                response += `</ul><p><strong>Areas for Improvement:</strong></p><ul>`;
                
                // Add some missing keywords
                const missing = jobKeywords.filter(keyword => !matches.includes(keyword));
                for (let i = 0; i < Math.min(3, missing.length); i++) {
                    response += `<li>Consider adding more details about your experience with "${missing[i]}"</li>`;
                }
                
                response += `</ul>
                <p><strong>Overall Assessment:</strong> Your resume shows ${matchPercentage > 70 ? 'strong' : matchPercentage > 50 ? 'moderate' : 'some'} alignment with the job requirements. ${matchPercentage > 70 ? 'You appear to be a good fit for this role.' : matchPercentage > 50 ? 'With some adjustments, you could be a strong candidate.' : 'Consider tailoring your resume more specifically to this role.'}</p>`;
                
                analysisResults.innerHTML = response;
            }
            
            function simulateImprovementResponse(jobDescription, pdfText) {
                // Simple keyword matching
                const jobKeywords = extractKeywords(jobDescription);
                const resumeKeywords = extractKeywords(pdfText);
                const matches = jobKeywords.filter(keyword => 
                    resumeKeywords.some(rKeyword => 
                        rKeyword.toLowerCase().includes(keyword.toLowerCase()) || 
                        keyword.toLowerCase().includes(rKeyword.toLowerCase())
                    )
                );
                
                const matchPercentage = Math.round((matches.length / jobKeywords.length) * 100);
                const missing = jobKeywords.filter(keyword => 
                    !resumeKeywords.some(rKeyword => 
                        rKeyword.toLowerCase().includes(keyword.toLowerCase()) || 
                        keyword.toLowerCase().includes(rKeyword.toLowerCase())
                    )
                );
                
                // Generate a simulated response
                let response = `<p><strong>ATS Match Score: ${matchPercentage}%</strong></p>
                <p><strong>Missing Keywords:</strong></p>
                <ul>`;
                
                for (let i = 0; i < Math.min(5, missing.length); i++) {
                    response += `<li>${missing[i]}</li>`;
                }
                
                response += `</ul>
                <p><strong>Skill Improvement Recommendations:</strong></p>
                <ul>`;
                
                // Generate recommendations based on missing keywords
                for (let i = 0; i < Math.min(3, missing.length); i++) {
                    response += `<li>Consider developing skills in ${missing[i]} through online courses or certification programs</li>`;
                }
                
                response += `</ul>
                <p><strong>Final Thoughts:</strong> To improve your match rate for this position, focus on highlighting any experience related to ${missing.slice(0, 3).join(', ')}. If you lack direct experience in these areas, consider using related skills or transferable experience to demonstrate your capability.</p>`;
                
                analysisResults.innerHTML = response;
            }
            
            // Simple keyword extraction (in a real app, this would be much more sophisticated)
            function extractKeywords(text) {
                // Remove common words and extract potential keywords
                const stopWords = ['and', 'the', 'to', 'a', 'an', 'in', 'with', 'for', 'of', 'on', 'at', 'from', 'by'];
                const words = text.toLowerCase().match(/\b[a-z]{3,}\b/g) || [];
                const filteredWords = words.filter(word => !stopWords.includes(word));
                
                // Count word frequency
                const wordCount = {};
                filteredWords.forEach(word => {
                    wordCount[word] = (wordCount[word] || 0) + 1;
                });
                
                // Extract the most common words as keywords
                return Object.entries(wordCount)
                    .sort((a, b) => b[1] - a[1])
                    .slice(0, 15)
                    .map(entry => entry[0]);
            }
        });
    </script>
</body>
</html>
