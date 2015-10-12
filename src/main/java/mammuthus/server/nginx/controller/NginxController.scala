package mammuthus.server.nginx.controller

import com.google.inject.Inject
import mammuthus.server.nginx.service.NginxService
import net.csdn.annotation.rest.{At, BasicInfo, State}
import net.csdn.modules.http.{ApplicationController, RestRequest}
import net.liftweb.{json => SJSon}

/**
 * 9/7/15 WilliamZhu(allwefantasy@gmail.com)
 */
class NginxController @Inject()(ngxService: NginxService) extends ApplicationController {
  implicit val formats = SJSon.Serialization.formats(SJSon.NoTypeHints)

  @At(path = Array("/add/servers/to/upstream"), types = Array(RestRequest.Method.GET, RestRequest.Method.POST))
  @BasicInfo(
    desc = "",
    state = State.alpha,
    testParams = "?name=&ips=",
    testResult = "",
    author = "WilliamZhu",
    email = "allwefantasy@gmail.com"
  )
  def addServersToUpstream = {
    val res = ngxService.addServersToUpstream(param("name"), param("ips", "").split(",").toList)
    if (res._1 == 0) render(200, "success")
    else {
      render(500, res._2)
    }

  }

  @At(path = Array("/remove/servers/from/upstream"), types = Array(RestRequest.Method.GET, RestRequest.Method.POST))
  @BasicInfo(
    desc = "",
    state = State.alpha,
    testParams = "?name=&ips=",
    testResult = "",
    author = "WilliamZhu",
    email = "allwefantasy@gmail.com"
  )
  def removeServersFromUpstream = {
    val res = ngxService.removeServersFromUpstream(param("name"), param("ips", "").split(",").toList)
    if (res._1 == 0) render(200, "success")
    else {
      render(500, res._2)
    }
  }
}
