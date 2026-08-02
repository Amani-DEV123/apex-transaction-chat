create or replace PROCEDURE APEX_ADD_CHAT (
    P_FILE_COLL IN VARCHAR2,
    P_FLAG      OUT VARCHAR2,
    P_MSG       OUT VARCHAR2
)
IS
    V_CHAT_ID NUMBER;

    CURSOR FILES IS
        SELECT
            C001    AS P_FILENAME,
            C002    AS P_MIME_TYPE,
            BLOB001 AS P_FILE_CONTENT
        FROM APEX_COLLECTIONS
        WHERE COLLECTION_NAME = P_FILE_COLL;

BEGIN

    -- Validate message
    IF TRIM(V('P5_CHAT_TXT')) IS NULL THEN
        P_FLAG := 'F';
        P_MSG  := 'Please enter a message.';
        RETURN;
    END IF;

    -- Validate chat type
    IF V('P5_CHAT_TYPE') IS NULL THEN
        P_FLAG := 'F';
        P_MSG  := 'Please select the chat type.';
        RETURN;
    END IF;

    -- Insert chat message
    INSERT INTO CHAT_MSG
    (
        TRANS_PK,
        TRANS_TYPE,
        CHAT_TXT,
        CHAT_DATE,
        G_USER_ID,
        CHAT_TYPE_FLAG
    )
    VALUES
    (
        V('P5_TRANS_PK'),
        V('P5_TRANS_TYPE'),
        TRIM(V('P5_CHAT_TXT')),
        SYSDATE,
        V('G_USER_ID'),
        V('P5_CHAT_TYPE')
    )
    RETURNING CHAT_ID_M
    INTO V_CHAT_ID;

    -- Insert attachments (optional)
    IF APEX_COLLECTION.COLLECTION_EXISTS(P_FILE_COLL) THEN

        FOR R IN FILES LOOP

            INSERT INTO CHAT_ATTACHMENTS
            (
                CHAT_ID,
                FILE_NAME,
                MIME_TYPE,
                FILE_CONTENT
            )
            VALUES
            (
                V_CHAT_ID,
                R.P_FILENAME,
                R.P_MIME_TYPE,
                R.P_FILE_CONTENT
            );

        END LOOP;

        APEX_COLLECTION.DELETE_COLLECTION(P_FILE_COLL);

    END IF;

    P_FLAG := 'T';
    P_MSG  := 'Message sent successfully.';

EXCEPTION
    WHEN OTHERS THEN
        P_FLAG := 'F';
        P_MSG  := 'Unable to send the message. Please try again.';
END APEX_ADD_CHAT;
/