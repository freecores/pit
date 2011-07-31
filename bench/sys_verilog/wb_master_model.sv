///////////////////////////////////////////////////////////////////////
////                                                               ////
////  WISHBONE rev.B2 Wishbone Master model                        ////
////                                                               ////
////                                                               ////
////  Author: Richard Herveille                                    ////
////          richard@asics.ws                                     ////
////          www.asics.ws                                         ////
////                                                               ////
////  Downloaded from: http://www.opencores.org/projects/mem_ctrl  ////
////                                                               ////
///////////////////////////////////////////////////////////////////////
////                                                               ////
//// Copyright (C) 2001 Richard Herveille                          ////
////                    richard@asics.ws                           ////
////                                                               ////
//// This source file may be used and distributed without          ////
//// restriction provided that this copyright statement is not     ////
//// removed from the file and that any derivative work contains   ////
//// the original copyright notice and the associated disclaimer.  ////
////                                                               ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY       ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR        ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,           ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES      ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE     ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR          ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT    ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           ////
//// POSSIBILITY OF SUCH DAMAGE.                                   ////
////                                                               ////
///////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: wb_master_model.v,v 1.4 2004/02/28 15:40:42 rherveille Exp $
//
//  $Date: 2004/02/28 15:40:42 $
//  $Revision: 1.4 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//
`include "timescale.v"

module wb_master_model  #(parameter dwidth = 32,
                          parameter awidth = 32)
(
output logic                 cyc,
output logic                 stb,
output logic                 we,
output logic [dwidth/8 -1:0] sel,
output logic [awidth   -1:0] adr,
output logic [dwidth   -1:0] dout,
input  logic [dwidth   -1:0] din,
input  logic                 clk,
input  logic                 ack,
input  logic                 rst,  // No Connect
input  logic                 err,  // No Connect
input  logic                 rty   // No Connect
);

////////////////////////////////////////////////////////////////////
//
// Local Wires
//


logic [dwidth   -1:0] q;

event cmp_error_detect;

////////////////////////////////////////////////////////////////////
//
// Memory Logic
//

initial
  begin
    adr  = 'x;
    dout = 'x;
    cyc  = 1'b0;
    stb  = 1'bx;
    we   = 1'hx;
    sel  = 'x;
    #1;
    $display("\nINFO: WISHBONE MASTER MODEL INSTANTIATED (%m)");
  end

////////////////////////////////////////////////////////////////////
//
// Wishbone write cycle
//

task wb_write(
  integer delay,
  logic   [awidth -1:0] a,
  logic   [dwidth -1:0] d);

  // wait initial delay
  repeat(delay) @(posedge clk);

  // assert wishbone signal
  #1;
  adr  = a;
  dout = d;
  cyc  = 1'b1;
  stb  = 1'b1;
  we   = 1'b1;
  sel  = '1;
  @(posedge clk);

  // wait for acknowledge from slave
  while(~ack)     @(posedge clk);

  // negate wishbone signals
  #1;
  cyc  = 1'b0;
  stb  = 1'bx;
  adr  = 'x;
  dout = 'x;
  we   = 1'hx;
  sel  = 'x;

endtask

////////////////////////////////////////////////////////////////////
//
// Wishbone read cycle
//

task wb_read(
  integer delay,
  logic         [awidth -1:0] a,
  output logic  [dwidth -1:0] d);

  // wait initial delay
  repeat(delay) @(posedge clk);

  // assert wishbone signals
  #1;
  adr  = a;
  dout = 'x;
  cyc  = 1'b1;
  stb  = 1'b1;
  we   = 1'b0;
  sel  = '1;
  @(posedge clk);

  // wait for acknowledge from slave
  while(~ack)     @(posedge clk);

  // negate wishbone signals
  d    = din; // Grab the data on the posedge of clock
  #1;         // Delay the clearing (hold time of the control signals
  cyc  = 1'b0;
  stb  = 1'bx;
  adr  = 'x;
  dout = 'x;
  we   = 1'hx;
  sel  = 'x;
  d    = din;

endtask

////////////////////////////////////////////////////////////////////
//
// Wishbone compare cycle (read data from location and compare with expected data)
//

task wb_cmp(
  integer delay,
  logic [awidth -1:0] a,
  logic [dwidth -1:0] d_exp);

  wb_read (delay, a, q);

  if (d_exp !== q)
    begin
      -> cmp_error_detect;
      $display("Data compare error at address %h. Received %h, expected %h at time %t", a, q, d_exp, $time);
    end
endtask

endmodule


