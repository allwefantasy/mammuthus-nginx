package mammuthus.server.nginx.sdk

import net.csdn.annotation.rest.{At, BasicInfo, State}
import net.csdn.modules.http.RestRequest
import net.csdn.modules.transport.HttpTransportService.SResponse

/**
 * 9/7/15 WilliamZhu(allwefantasy@gmail.com)
 */
trait NginxClientService {
  @At(path = Array("/add/servers/to/upstream"), types = Array(RestRequest.Method.GET, RestRequest.Method.POST))
  @BasicInfo(
    desc = "",
    state = State.alpha,
    testParams = "?name=&ips=",
    testResult = "",
    author = "WilliamZhu",
    email = "allwefantasy@gmail.com"
  )
  def addServersToUpstream(name: String, ips: String): SResponse

  @At(path = Array("/remove/servers/from/upstream"), types = Array(RestRequest.Method.GET, RestRequest.Method.POST))
  @BasicInfo(
    desc = "",
    state = State.alpha,
    testParams = "?name=&ips=",
    testResult = "",
    author = "WilliamZhu",
    email = "allwefantasy@gmail.com"
  )
  def removeServersFromUpstream(name: String, ips: String): SResponse

}
