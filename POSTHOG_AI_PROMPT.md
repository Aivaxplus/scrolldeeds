# Prompt voor PostHog AI

Kopieer de hele blok hieronder en plak in PostHog AI (in je PostHog dashboard).

---

```
I have a mobile app (ScrollDeeds) with an onboarding flow. The funnel is: Get Started → Questionnaire (many steps) → Paywall → Thank You. Here are the events I send:

1. "Get Started Viewed" – when the first screen (Break Phone Addiction / Start Your Journey) is shown. No properties.

2. "Get Started CTA Clicked" – when the user taps "Start Your Journey" and goes to the questionnaire. No properties.

3. "Onboarding Started" – when the questionnaire starts (first step shown). No properties.

4. "Onboarding Step Viewed" – every time a questionnaire step is shown. Properties:
   - step_number (0, 1, 2, …)
   - step_name (localized title)
   - step_type (e.g. info, reflection, question, slider_question, visual, commitment, app_selection, difficulty_selection)
   - total_steps (total number of steps in the flow – can change when we add/remove steps)
   - step_identifier (e.g. step_0_info, step_1_reflection, step_5_slider_question – use this for stable funnel filters)
   - time_on_previous_step (seconds on the previous step)

5. "Onboarding Completed" – when the user finishes the questionnaire. Properties:
   - total_steps, total_time_seconds, apps_selected, difficulty_level

6. "Onboarding Abandoned" – when the user leaves before finishing (e.g. closes app). Properties:
   - step_number, step_name, step_identifier, total_steps, progress_percent, total_time_seconds

7. "Paywall Viewed" – when the paywall is shown (after questionnaire). No properties.

8. "Thank You Viewed" – when the thank-you page is shown after successful purchase. No properties.

Please help me:
1. Build the full funnel: Get Started Viewed → Get Started CTA Clicked → Onboarding Started → Onboarding Step Viewed (filter by step_identifier or step_number) → Onboarding Completed → Paywall Viewed → Thank You Viewed. Show conversion at each step.
2. Show drop-off: use "Onboarding Abandoned" to see where users leave and progress_percent.
3. Show completion rate over time (Onboarding Completed / Onboarding Started, and Thank You Viewed / Paywall Viewed for paywall conversion).
4. Suggest which steps to optimize based on drop-off and time_on_previous_step.
```
