import base64
import io
import os
from dotenv import load_dotenv  # type:ignore
load_dotenv()

import streamlit as st
import pypdf  # Corrected import statement
import google.generativeai as genai  # type:ignore

# Configure Gemini API key - using environment variable properly
api_key = os.getenv("GEMINI_API_KEY")  # Change the variable name in your .env file
if not api_key:
    st.error("API key not found. Please add GEMINI_API_KEY to your .env file.")
    st.stop()

genai.configure(api_key=api_key)

# Gemini call function
def get_gemini_response(input_instruction, pdf_text, job_description):
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content([input_instruction, pdf_text, job_description])
        return response.text
    except Exception as e:
        st.error(f"Error generating response: {str(e)}")
        return None

# Extract text from uploaded PDF
def input_pdf_setup(uploaded_file):
    if uploaded_file is not None:
        try:
            reader = pypdf.PdfReader(uploaded_file)  # Using correct module name
            full_text = ""
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    full_text += page_text + "\n"
            if not full_text.strip():
                st.error("No readable text found in the uploaded PDF.")
                return None
            return full_text
        except Exception as e:
            st.error(f"Error processing PDF: {str(e)}")
            return None
    else:
        st.warning("No file uploaded")
        return None

# Streamlit UI setup
st.set_page_config(page_title="ATS Resume Expert", layout="centered")
st.markdown("<h1 style='text-align:center;color: #4B8BBE;'>ATS Resume Expert</h1>", unsafe_allow_html=True)  # Fixed title inconsistency
st.markdown("Enter the job description below")

# User input
input_text = st.text_area("Job Description", key="input", height=200)
uploaded_file = st.file_uploader("Upload your resume (PDF only)", type=["pdf"])
if uploaded_file:
    st.success("Resume uploaded successfully!")

# Action buttons
col1, col2 = st.columns(2)
with col1:
    submit1 = st.button("Tell me about the resume")
with col2:
    submit2 = st.button("How can I improve my skills?")

# Prompts
input_prompt1 = """
You are an experienced technical human resource Manager. Your task is to review the provided resume against the job description.
Please share your professional evaluation on whether the candidate's profile aligns with the role.
Highlight the strengths and weaknesses of the applicant in relation to the specified job requirements.
"""

input_prompt2 = """
You are a skilled ATS (Applicant Tracking System) scanner with a deep understanding of data science and ATS functionality.
Your task is to evaluate the resume against the provided job description. Give me the percentage of match if the resume fits
the job description. First the output should come as percentage, then keywords missing, and finally final thoughts.
"""

# Evaluation
if submit1:
    if uploaded_file and input_text:  # Added check for job description
        pdf_text = input_pdf_setup(uploaded_file)
        if pdf_text:
            with st.spinner("Analyzing resume..."):
                response = get_gemini_response(input_prompt1, pdf_text, input_text)
                if response:
                    st.subheader("Analysis Results")
                    st.write(response)
    elif not uploaded_file:
        st.warning("Please upload your resume.")
    elif not input_text:
        st.warning("Please enter a job description.")

elif submit2:
    if uploaded_file and input_text:  # Added check for job description
        pdf_text = input_pdf_setup(uploaded_file)
        if pdf_text:
            with st.spinner("Analyzing resume and generating recommendations..."):
                response = get_gemini_response(input_prompt2, pdf_text, input_text)
                if response:
                    st.subheader("Analysis Results")
                    st.write(response)
    elif not uploaded_file:
        st.warning("Please upload your resume.")
    elif not input_text:
        st.warning("Please enter a job description.")