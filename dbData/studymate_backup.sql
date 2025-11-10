--
-- PostgreSQL database dump
--

\restrict RaE5kfOtpjxrbcjwylikQVp5FmcbsLnVSGyllQNwlsd3VPWnqKRzf1Q7hmm4q5g

-- Dumped from database version 17.6 (Ubuntu 17.6-1.pgdg22.04+1)
-- Dumped by pg_dump version 17.6 (Ubuntu 17.6-1.pgdg22.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: goals; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.goals (goal_id, user_id, goal_text, target_date, is_completed, created_at) FROM stdin;
2	2	Finish Advance Web Project	2025-11-08	f	2025-11-08 22:43:45-06
3	2	Complete Calculus Practice Problems	2025-11-10	f	2025-11-09 14:45:14-06
4	2	Read 3 Chapters of Networking Book	2025-11-11	f	2025-11-09 14:45:26-06
5	2	Finish Final Report for IT Project	2025-11-12	f	2025-11-09 14:45:33-06
6	2	Prepare Slides for Presentation	2025-11-13	f	2025-11-09 14:45:42-06
7	2	Submit Internship Assignment	2025-11-14	f	2025-11-09 14:45:48-06
8	2	Review Past Exam Papers	2025-11-15	f	2025-11-09 14:45:55-06
9	2	Complete Coding Challenge	2025-11-16	f	2025-11-09 14:46:05-06
10	2	Organize Study Notes	2025-11-17	f	2025-11-09 14:46:20-06
11	2	Practice SQL Queries	2025-11-18	f	2025-11-09 14:46:31-06
12	2	Update Portfolio Website	2025-11-19	f	2025-11-09 14:46:40-06
13	2	Attend Online Webinar on Cloud Computing	2025-11-20	f	2025-11-09 14:46:52-06
14	2	Plan Next Week Study Schedule	2025-11-21	f	2025-11-09 14:47:02-06
15	2	Complete Practice Exams	2025-11-22	f	2025-11-09 14:47:19-06
16	2	Learn New Golang Package	2025-11-23	f	2025-11-09 14:47:28-06
17	2	Learn New Golang Package	2025-11-23	f	2025-11-09 14:47:36-06
18	2	Write Technical Blog Post	2025-11-24	f	2025-11-09 14:47:53-06
19	2	Test REST API Endpoints	2025-11-25	f	2025-11-09 14:48:07-06
20	2	Review Security Best Practices	2025-11-26	f	2025-11-09 14:48:24-06
21	2	Practice Data Structures Problems	2025-11-27	f	2025-11-09 14:48:36-06
22	2	Update LinkedIn Profile	2025-11-28	f	2025-11-09 14:48:45-06
23	2	Finalize Group Project Submission	2025-11-29	f	2025-11-09 14:48:52-06
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.permissions (id, code) FROM stdin;
1	quotes:read
2	quotes:write
3	goals:read
4	goals:write
5	study_sessions:read
6	study_sessions:write
7	users:read
8	users:write
\.


--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.quotes (quote_id, user_id, content, created_at) FROM stdin;
2	2	Discipline is doing what needs to be done, even when you don’t feel like doing it.	2025-11-09 14:40:10-06
3	2	Small steps each day add up to big results over time.	2025-11-09 14:40:26-06
4	2	You only fail when you stop trying.	2025-11-09 14:40:36-06
5	2	Dream big, start small, act now.	2025-11-09 14:40:54-06
6	2	Success is the sum of consistent effort, not luck.	2025-11-09 14:41:06-06
7	2	Your future self will thank you for not giving up today.	2025-11-09 14:41:19-06
8	2	Focus on progress, not perfection.	2025-11-09 14:41:39-06
9	2	Great things never come from comfort zones.	2025-11-09 14:41:49-06
10	2	The best view comes after the hardest climb.	2025-11-09 14:42:00-06
11	2	Push yourself, because no one else is going to do it for you.	2025-11-09 14:42:09-06
12	2	You are stronger than you think and braver than you believe.	2025-11-09 14:42:18-06
13	2	If it matters to you, you’ll find a way. If not, you’ll find an excuse.	2025-11-09 14:42:26-06
14	2	Work hard in silence, let success make the noise.	2025-11-09 14:42:36-06
15	2	Don’t wish for it, work for it.	2025-11-09 14:42:44-06
16	2	It always seems impossible until it’s done.	2025-11-09 14:42:54-06
17	2	One day or day one. You decide.	2025-11-09 14:43:01-06
18	2	Stay consistent. The results will come.	2025-11-09 14:43:13-06
19	2	Don’t count the days, make the days count.	2025-11-09 14:43:23-06
20	2	A year from now, you’ll wish you started today.	2025-11-09 14:43:35-06
21	2	Be the hardest worker in the room.	2025-11-09 14:43:51-06
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.schema_migrations (version, dirty) FROM stdin;
9	f
\.


--
-- Data for Name: study_sessions; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.study_sessions (session_id, user_id, title, description, subject, start_time, end_time, is_completed, created_at) FROM stdin;
2	2	Review Chapter 5	Example problems and practice exercises on vector spaces.	Linear Algebra	14:00:00	16:00:00	t	2025-11-09 13:58:29-06
3	2	Review Chapter 5	Go through all example problems and practice exercises on vector spaces.	Linear Algebra	14:00:00	16:00:00	f	2025-11-09 14:50:11-06
4	2	Practice Calculus Problems	Solve integrals and derivatives from past exams.	Calculus	10:00:00	12:00:00	f	2025-11-09 14:50:24-06
5	2	Read Networking Chapter 3	Understand OSI model and TCP/IP protocols.	Networking	09:00:00	11:00:00	f	2025-11-09 14:50:35-06
6	2	Practice SQL Queries	Write SELECT, JOIN, and aggregate queries on sample database.	Databases	13:00:00	15:00:00	f	2025-11-09 14:50:44-06
7	2	Review Security Best Practices	Go through authentication and authorization mechanisms.	Cybersecurity	14:00:00	16:00:00	f	2025-11-09 14:50:56-06
8	2	Study Operating Systems	Focus on process scheduling and memory management.	Operating Systems	09:00:00	11:00:00	f	2025-11-09 14:51:05-06
9	2	Practice Golang Exercises	Implement functions, structs, and slices.	Programming	10:00:00	12:00:00	f	2025-11-09 14:51:13-06
10	2	Review Past Exam Papers	Solve previous IT exam questions.	Information Technology	14:00:00	16:00:00	f	2025-11-09 14:51:26-06
11	2	Update Portfolio Website	Add new projects and update resume section.	Web Development	11:00:00	13:00:00	f	2025-11-09 14:51:35-06
12	2	Prepare Presentation Slides	Create slides for upcoming class presentation.	Technical Writing	15:00:00	17:00:00	f	2025-11-09 14:51:42-06
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.users (id, username, email, password_hash, activated, version, created_at) FROM stdin;
2	aiyeshacole	aiyeshacole@example.com	\\x243261243130243168624a4945777a75316a475a6741373233673454756841694b65474b4e4c4963576d636876325974744175797637656647497657	t	4	2025-11-06 07:21:05-06
\.


--
-- Data for Name: tokens; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.tokens (hash, user_id, expiry, scope) FROM stdin;
\\x055e4f15dc887f1d26daefe20da257ab713c042de4c6ba7eb63fc6f4e767a1e3	2	2025-11-09 10:50:21-06	authentication
\\x198936790e263933ba25f45e6766c22a77472154aa8171510817e4cb6b48ac7d	2	2025-11-09 21:10:44-06	authentication
\\x3eb4c3608a583341ba4b39479340ecc5144b9bc5014c520f6fd75c8cca9d1e31	2	2025-11-10 12:01:39-06	authentication
\.


--
-- Data for Name: users_permissions; Type: TABLE DATA; Schema: public; Owner: studymate
--

COPY public.users_permissions (user_id, permission_id) FROM stdin;
2	1
2	2
2	3
2	4
2	5
2	6
2	7
2	8
\.


--
-- Name: goals_goal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: studymate
--

SELECT pg_catalog.setval('public.goals_goal_id_seq', 23, true);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: studymate
--

SELECT pg_catalog.setval('public.permissions_id_seq', 8, true);


--
-- Name: quotes_quote_id_seq; Type: SEQUENCE SET; Schema: public; Owner: studymate
--

SELECT pg_catalog.setval('public.quotes_quote_id_seq', 21, true);


--
-- Name: study_sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: studymate
--

SELECT pg_catalog.setval('public.study_sessions_session_id_seq', 12, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: studymate
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- PostgreSQL database dump complete
--

\unrestrict RaE5kfOtpjxrbcjwylikQVp5FmcbsLnVSGyllQNwlsd3VPWnqKRzf1Q7hmm4q5g

