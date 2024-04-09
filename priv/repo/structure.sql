--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
-- Dumped by pg_dump version 15.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: link_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.link_visits (
    link_id uuid NOT NULL,
    date date NOT NULL,
    hour smallint NOT NULL,
    count integer DEFAULT 0,
    CONSTRAINT positive_count CHECK ((count >= 0)),
    CONSTRAINT valid_hour CHECK (((hour >= 0) AND (hour <= 23)))
);


--
-- Name: links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.links (
    id uuid NOT NULL,
    slug character varying(16) NOT NULL,
    original_url character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.users IS 'Placeholder table for stubbed authz/authn implementation';


--
-- Name: link_visits link_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.link_visits
    ADD CONSTRAINT link_visits_pkey PRIMARY KEY (link_id, date, hour);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: link_visits_link_id_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX link_visits_link_id_date_index ON public.link_visits USING btree (link_id, date);


--
-- Name: links_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX links_inserted_at_index ON public.links USING btree (inserted_at);


--
-- Name: links_original_url_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX links_original_url_index ON public.links USING btree (original_url);


--
-- Name: links_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX links_slug_index ON public.links USING btree (slug);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: link_visits id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.link_visits
    ADD CONSTRAINT id FOREIGN KEY (link_id) REFERENCES public.links(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: links links_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20240409135116);
INSERT INTO public."schema_migrations" (version) VALUES (20240409143510);
INSERT INTO public."schema_migrations" (version) VALUES (20240409201910);
INSERT INTO public."schema_migrations" (version) VALUES (20240409202044);
