alias MixDependencySubmission.ApiClient

Application.put_env(:mix_dependency_submission, ApiClient, plug: {Req.Test, ApiClient})

ExUnit.start(capture_log: true)
