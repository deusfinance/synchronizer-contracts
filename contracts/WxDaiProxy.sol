//Be name khoda

pragma solidity 0.8.1;

interface Synchronizer{
	function buyFor(
		address _user,
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	) external;

	function sellFor(
		address _user,
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	)
		external;
}

interface Wxdai {
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function deposit() external payable;
	function withdraw(uint wad) external;
}

interface Registrar {
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract wxdaiProxy{

	Synchronizer public synchronizer;
	Wxdai public wxdai;
	uint256 public scale = 1e18;

	constructor(address _synchronizer, address _wxdai){
		wxdai = Wxdai(_wxdai);
		synchronizer = Synchronizer(_synchronizer);
		wxdai.approve(_synchronizer, 1e50);
	}

	function setSynchronizer(address _synchronizer) public{
		synchronizer = Synchronizer(_synchronizer);
		wxdai.approve(_synchronizer, 1e50);
	}

	function calculateXdaiAmount(uint256 price, uint256 fee, uint256 amount) public view returns (uint256){
		uint256 collateralAmount = (price*amount)/scale;
		uint256 feeAmount = (collateralAmount*fee)/scale;
		return collateralAmount+feeAmount;
	}
	
	function buy(
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	)
		external payable
	{
		wxdai.deposit{value:msg.value}();
		synchronizer.buyFor(msg.sender, multiplier, registrar, amount, fee, blockNos, prices, v, r, s);
	}

	function sell(
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	)
		external
	{
		Registrar(registrar).transferFrom(msg.sender, address(this), amount);
		synchronizer.sellFor(address(this), multiplier, registrar, amount, fee, blockNos, prices, v, r, s);
		uint256 wxdaiAmount = wxdai.balanceOf(address(this)); 
		wxdai.withdraw(wxdaiAmount);
		payable(msg.sender).transfer(wxdaiAmount);
	}
	

	receive() external payable {
		// receive ether
	}

}

//Dar panah khoda