# ==============================================================================
# Amazon Bedrock Guardrail for the company-handbook assistant
#
# A guardrail is a model-independent policy layer. It evaluates the user's
# input before the model runs and the model's output before it is returned, and
# it can also be called on its own (ApplyGuardrail). Here it backs the RAG
# assistant from bedrock-kb.tf:
#
#   user ──► [input checks] ──► Knowledge Base + Nova Lite ──► [output checks] ──► user
#
# Contextual grounding is the RAG-specific check: it scores the answer against
# the retrieved chunks and blocks answers the documents don't support.
# See docs/bedrock-guardrail.md.
# ==============================================================================

resource "aws_bedrock_guardrail" "company_handbook" {
  name        = local.bedrock_guardrail_name
  description = "Safety, PII, topic and grounding policy for the company-handbook RAG assistant (lab)"

  # Returned in place of the blocked input or output.
  blocked_input_messaging   = "Sorry, I can't help with that request. Please ask about Example Corp policies."
  blocked_outputs_messaging = "Sorry, I couldn't produce an answer that is supported by the company handbook."

  # 1. Content filters -----------------------------------------------------------
  # Harmful-content classifiers. A filter's strength sets how confident the
  # classifier must be before blocking: HIGH blocks the most.
  content_policy_config {
    dynamic "filters_config" {
      for_each = ["HATE", "INSULTS", "SEXUAL", "VIOLENCE", "MISCONDUCT"]
      content {
        type            = filters_config.value
        input_strength  = "HIGH"
        output_strength = "HIGH"
      }
    }

    # Jailbreak and prompt-injection detection. It applies to input only, so the
    # output strength must be NONE.
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE"
    }
  }

  # 2. Denied topics ---------------------------------------------------------------
  # Topics are described in plain language and matched semantically, not by
  # keyword. A definition says what the topic is, not what to do about it.
  topic_policy_config {
    topics_config {
      name       = "Legal advice"
      type       = "DENY"
      definition = "Requests for legal opinions or advice about an individual's rights, lawsuits, disputes or contracts, beyond restating what a company policy says."
      examples = [
        "Can I sue the company if my expense report is rejected?",
        "Is my employment contract legally enforceable?",
      ]
    }

    topics_config {
      name       = "Individual compensation"
      type       = "DENY"
      definition = "Questions about the salary, bonus, equity or pay of a specific named employee or group of employees."
      examples = [
        "How much does my manager earn?",
        "What is the CTO's bonus this year?",
      ]
    }
  }

  # 3. Word filters ------------------------------------------------------------------
  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }

    # Exact-match blocklist, for terms a business never wants echoed back.
    words_config {
      text = "Project Nightingale"
    }
  }

  # 4. Sensitive information -----------------------------------------------------------
  # BLOCK rejects the whole message; ANONYMIZE replaces the entity with a
  # placeholder such as {EMAIL} and lets the rest through. Secrets and payment
  # data are blocked outright; contact details are masked.
  sensitive_information_policy_config {
    dynamic "pii_entities_config" {
      for_each = {
        EMAIL                     = "ANONYMIZE"
        PHONE                     = "ANONYMIZE"
        US_SOCIAL_SECURITY_NUMBER = "BLOCK"
        CREDIT_DEBIT_CARD_NUMBER  = "BLOCK"
        PASSWORD                  = "BLOCK"
        AWS_ACCESS_KEY            = "BLOCK"
        AWS_SECRET_KEY            = "BLOCK"
      }
      content {
        type   = pii_entities_config.key
        action = pii_entities_config.value
      }
    }

    # Custom identifiers the built-in PII types don't know about.
    regexes_config {
      name        = "Employee ID"
      description = "Example Corp employee IDs, for example EC-123456"
      pattern     = "\\bEC-[0-9]{6}\\b"
      action      = "ANONYMIZE"
    }
  }

  # 5. Contextual grounding --------------------------------------------------------------
  # Scored 0–1 on each response; below the threshold, the response is blocked.
  #   GROUNDING: is the answer supported by the retrieved source chunks?
  #   RELEVANCE: does the answer address the user's question?
  # Higher thresholds block more hallucination, and also more correct answers
  # that paraphrase heavily. Tune with the test set in the runbook.
  contextual_grounding_policy_config {
    filters_config {
      type      = "GROUNDING"
      threshold = 0.75
    }

    filters_config {
      type      = "RELEVANCE"
      threshold = 0.5
    }
  }

  tags = {
    Name = local.bedrock_guardrail_name
  }
}

# Callers reference an immutable numbered version, not the mutable DRAFT, so
# editing the policy can't silently change production behaviour. Any change to
# the guardrail replaces this resource, which publishes the next version.
# skip_destroy keeps old versions, so anything pinned to them keeps working.
resource "aws_bedrock_guardrail_version" "company_handbook" {
  guardrail_arn = aws_bedrock_guardrail.company_handbook.guardrail_arn
  description   = "Managed by Terraform"
  skip_destroy  = true

  lifecycle {
    replace_triggered_by = [aws_bedrock_guardrail.company_handbook]
  }
}
